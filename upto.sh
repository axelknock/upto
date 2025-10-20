#!/bin/sh
# upto DURATION CMD [ARGS...]
# exit 124 on idle timeout; else exit with CMD's status.

usage() { echo "usage: upto DURATION CMD [ARGS...]" >&2; exit 2; }

parse_secs() {
  v=$1
  n=${v%[smhdSMHD]}
  u=${v#$n}
  [ -z "$n" ] && usage
  case $n in (*[!0-9]*) echo "invalid duration: $v" >&2; exit 2;; esac
  [ -z "$u" ] && u=s
  case $u in
    s|S) m=1;;
    m|M) m=60;;
    h|H) m=3600;;
    d|D) m=86400;;
    *) echo "invalid unit in duration: $v" >&2; exit 2;;
  esac
  echo $(( n * m ))
}

[ $# -lt 2 ] && usage
idle_secs=$(parse_secs "$1"); shift

# temp fifo for merging stdout+stderr without subshelling away state
fifo=$(mktemp -u); mkfifo "$fifo" || { echo "mkfifo failed" >&2; exit 2; }
cleanup() {
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
  rm -f "$fifo"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

# open the fifo for reading on fd 3 first so writer can connect
exec 3<"$fifo"

# run the command, writing both stdout+stderr to fifo
( exec "$@" >"$fifo" 2>&1 ) & pid=$!

# read lines with a timeout; kill on idle
# if the command ends (EOF), propagate its status.
while :; do
  # POSIX 'read -t' is in seconds; times out if no full line arrives.
  if IFS= read -r -t "$idle_secs" line <&3; then
    printf '%s\n' "$line"
    continue
  fi

  # read failed: either timeout (still running) or EOF (process ended)
  if kill -0 "$pid" 2>/dev/null; then
    # still running but silent -> idle timeout
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    exit 124
  else
    # process ended; drain remaining data if any (best-effort)
    while IFS= read -r line <&3; do
      printf '%s\n' "$line"
    done
    wait "$pid"; rc=$?
    exit "$rc"
  fi
done

