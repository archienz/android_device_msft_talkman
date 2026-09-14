#!/vendor/bin/sh
# Recover /data/misc/radio/qcril.db from /system/etc/qcril.db.
# exec_start from post-fs-data (after /data), before class main rild.
# Does not start rild. Owner radio:radio 660 (AID_RADIO 1001).

DB=/data/misc/radio/qcril.db
SRC=/system/etc/qcril.db

recover_qcril() {
	rm -f "$DB" "${DB}-journal" "${DB}-wal" "${DB}-shm"
	[ -f "$SRC" ] || return 1
	cp "$SRC" "$DB" || return 1
	# toolbox accepts radio:radio; some sh only radio.radio
	chown radio:radio "$DB" 2>/dev/null || chown radio.radio "$DB"
	chmod 660 "$DB"
}

need_recover=0

if [ ! -f "$DB" ]; then
	need_recover=1
else
	SQL=
	# Probe: binary exists AND actually runs (sepolicy may block vendor→system).
	if [ -x /system/bin/sqlite3 ] && \
	   /system/bin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
		SQL=/system/bin/sqlite3
	elif [ -x /system/xbin/sqlite3 ] && \
	     /system/xbin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
		SQL=/system/xbin/sqlite3
	elif [ -x /vendor/bin/sqlite3 ] && \
	     /vendor/bin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
		SQL=/vendor/bin/sqlite3
	fi

	if [ -n "$SQL" ]; then
		ic=$($SQL "$DB" "PRAGMA integrity_check;" 2>/dev/null) || ic=
		ic=$(printf '%s\n' "$ic" | head -n 1 | tr -d '\r')
		[ "$ic" = "ok" ] || need_recover=1
	else
		# No usable sqlite3. Tiny tool: SQLite magic via head (toybox).
		# Page-corrupt with a valid header is not detected — then
		# recover if journal/wal/shm is present (always-if-journal).
		hdr=$(head -c 15 "$DB" 2>/dev/null)
		if [ "$hdr" != "SQLite format 3" ]; then
			need_recover=1
		elif [ -e "${DB}-journal" ] || [ -e "${DB}-wal" ] || [ -e "${DB}-shm" ]; then
			need_recover=1
		fi
	fi
fi

if [ "$need_recover" = 1 ]; then
	recover_qcril
fi

exit 0
