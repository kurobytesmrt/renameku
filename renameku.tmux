#!/data/data/com.termux/files/usr/bin/bash

# RenameKu PRO+
# Features:
# - replaceall with preview & highlight
# - backup before replace (undo)
# - regex mode (optional)
# - ignore patterns (optional)
# - per-file confirm or Replace All with double confirm
# - progress & counts
# - other useful commands (rename, renameall, download, ls, cd, open, undo, help)

BLUE="\033[34m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

BACKUP_ROOT="$PWD/.renameku_backups"

clear
echo -e "${BLUE}You Entered RenameKu - Project${RESET}"
echo ""

# Ensure backup root exists
mkdir -p "$BACKUP_ROOT"

while true; do
    echo -ne "${BLUE}[renameku]${RESET} "
    read cmd args

    case "$cmd" in
        help)
            echo -e "${GREEN}Available commands:${RESET}"
            echo "  help                   - Show command list"
            echo "  rename                 - Rename single file"
            echo "  renameall [path]       - Rename file names in a folder (simple)"
            echo "  replaceall             - Replace text inside files (scan, preview, backup)"
            echo "  download               - Download from direct link"
            echo "  ls                     - List files"
            echo "  cd <path>              - Change directory"
            echo "  open <file>            - Show file content"
            echo "  undo                   - Restore from last backup"
            echo "  backups                - List available backups"
            echo "  clear                  - Clear screen"
            echo "  exit                   - Exit program"
            ;;

        rename)
            echo -ne "${BLUE}[renameku]${RESET} file name  : "
            read file
            echo -ne "${BLUE}[renameku]${RESET} new name   : "
            read newname
            if [ ! -e "$file" ]; then
                echo -e "${RED}File not found: $file${RESET}"
            else
                mv "$file" "$newname"
                echo -e "${GREEN}Renamed: $file → $newname${RESET}"
            fi
            ;;

        renameall)
            folder="$args"
            if [ -z "$folder" ]; then
                echo -e "${RED}Usage: renameall [pathtofolder]${RESET}"
                continue
            fi
            if [ ! -d "$folder" ]; then
                echo -e "${RED}Folder not found.${RESET}"
                continue
            fi

            echo -ne "${BLUE}[renameku]${RESET} find     : "
            read find
            echo -ne "${BLUE}[renameku]${RESET} replace  : "
            read replace

            for file in "$folder"/*"$find"*; do
                [ -e "$file" ] || continue
                newname="${file//$find/$replace}"
                echo -e "${BLUE}[renameku]${RESET} $(basename "$file") → $(basename "$newname")"
                mv "$file" "$newname"
            done

            echo -e "${GREEN}Mass rename complete!${RESET}"
            ;;

        replaceall)
            # 1) ask folder
            echo -ne "${BLUE}[renameku]${RESET} path folder : "
            read folder
            if [ ! -d "$folder" ]; then
                echo -e "${RED}Folder not found.${RESET}"
                continue
            fi

            # 2) find / replace
            echo -ne "${BLUE}[renameku]${RESET} Find    : "
            read find
            echo -ne "${BLUE}[renameku]${RESET} Replace : "
            read replace

            # 3) regex?
            echo -ne "${BLUE}[renameku]${RESET} Use regex? (Y/N) : "
            read use_regex
            if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                GREP_CMD="grep -Er"
                GREP_RL_OP="-rlE"
                SED_OPT="-E"
            else
                GREP_CMD="grep -F"
                GREP_RL_OP="-rlF"
                SED_OPT=""
            fi

            # 4) ignore patterns (comma sep)
            echo -ne "${BLUE}[renameku]${RESET} Ignore patterns (comma sep, optional e.g. node_modules,.git) : "
            read ignores_raw
            IGNORE_ARGS=()
            if [ -n "$ignores_raw" ]; then
                IFS=',' read -ra IGNS <<< "$ignores_raw"
                for ig in "${IGNS[@]}"; do
                    ig_trim="$(echo "$ig" | xargs)"
                    [ -n "$ig_trim" ] && IGNORE_ARGS+=(--exclude-dir="$ig_trim" --exclude="$ig_trim")
                done
            fi

            echo ""
            echo -e "${BLUE}[renameku]${RESET} Scanning files..."
            sleep 0.5

            # 5) build grep -rl command safely
            # Using eval to include ignore args array
            # Get list of files containing the pattern
            if [ -n "${IGNORE_ARGS[*]}" ]; then
                # build exclude as string
                EXCLUDE_STR=""
                for e in "${IGNORE_ARGS[@]}"; do
                    EXCLUDE_STR+=" $e"
                done
            fi

            # Use mapfile to capture results
            # We call grep with proper flags
            if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                # regex
                eval "mapfile -t files < <(grep -rlE \"$find\" \"$folder\" ${EXCLUDE_STR} 2>/dev/null)"
            else
                eval "mapfile -t files < <(grep -rlF \"$find\" \"$folder\" ${EXCLUDE_STR} 2>/dev/null)"
            fi

            if [ ${#files[@]} -eq 0 ]; then
                echo -e "${RED}No files contain '$find'.${RESET}"
                continue
            fi

            # 6) show files with match counts and preview of matches (first 3 lines)
            echo -e "${GREEN}Files found:${RESET}"
            i=1
            for f in "${files[@]}"; do
                # count matches (line occurrences)
                if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                    count=$(grep -oE "$find" "$f" 2>/dev/null | wc -l)
                else
                    count=$(grep -oF "$find" "$f" 2>/dev/null | wc -l)
                fi
                echo -e "${YELLOW}$i.${RESET} $(basename "$f")  ($count matches) — ${f}"
                # preview up to 3 matching lines with numbers & color
                if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                    grep -nE --color=always "$find" "$f" 2>/dev/null | sed -n '1,3p' || true
                else
                    grep -nF --color=always "$find" "$f" 2>/dev/null | sed -n '1,3p' || true
                fi
                echo ""
                ((i++))
            done

            # 7) Ask whether per-file or all
            echo -ne "${BLUE}[renameku]${RESET} Replace (Y for per-file, U for all, D for dry-run): "
            read choice

            # create backup snapshot folder
            SNAPSHOT_DIR="$BACKUP_ROOT/backup_$(date +%s)"
            mkdir -p "$SNAPSHOT_DIR"

            if [[ "$choice" =~ ^[Dd]$ ]]; then
                echo -e "${GREEN}Dry run: no files will be changed.${RESET}"
                echo "Files that WOULD be changed:"
                for f in "${files[@]}"; do
                    echo " - $f"
                done
                continue
            fi

            if [[ "$choice" =~ ^[Yy]$ ]]; then
                total=${#files[@]}
                done_count=0
                for f in "${files[@]}"; do
                    echo -ne "${BLUE}[renameku]${RESET} Replace in $(basename "$f")? (Y/N) "
                    read confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        # backup original file path (preserve folder tree)
                        relpath="$(realpath --relative-to="$PWD" "$f" 2>/dev/null || echo "$f")"
                        destdir="$(dirname "$SNAPSHOT_DIR/$relpath")"
                        mkdir -p "$destdir"
                        cp --preserve=all "$f" "$destdir/" 2>/dev/null || cp "$f" "$destdir/"

                        # perform replace (regex or literal)
                        if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                            sed -E -i "$SED_OPT s/$find/$replace/g" "$f" 2>/dev/null || sed -E -i "s/$find/$replace/g" "$f"
                        else
                            sed -i "s/$(printf '%s' "$find" | sed -e 's/[\/&]/\\&/g')/$(printf '%s' "$replace" | sed -e 's/[\/&]/\\&/g')/g" "$f"
                        fi

                        echo -e "${GREEN}Replaced in $f (backup saved).${RESET}"
                        ((done_count++))
                    else
                        echo "Skipped $f"
                    fi
                done
                if [ $done_count -gt 0 ]; then
                    echo -e "${GREEN}Done. Backup snapshot: ${SNAPSHOT_DIR}${RESET}"
                else
                    rmdir --ignore-fail-on-non-empty "$SNAPSHOT_DIR" 2>/dev/null || true
                    echo -e "${YELLOW}No files changed. No backup created.${RESET}"
                fi
            elif [[ "$choice" =~ ^[Uu]$ ]]; then
                echo -ne "${BLUE}[renameku]${RESET} You are sure? For Replace ALL Y/N : "
                read sure
                if [[ "$sure" =~ ^[Yy]$ ]]; then
                    total=${#files[@]}
                    count_done=0
                    echo "Applying replace to $total files..."
                    for f in "${files[@]}"; do
                        # backup
                        relpath="$(realpath --relative-to="$PWD" "$f" 2>/dev/null || echo "$f")"
                        destdir="$(dirname "$SNAPSHOT_DIR/$relpath")"
                        mkdir -p "$destdir"
                        cp --preserve=all "$f" "$destdir/" 2>/dev/null || cp "$f" "$destdir/"

                        # replace
                        if [[ "$use_regex" =~ ^[Yy]$ ]]; then
                            sed -E -i "$SED_OPT s/$find/$replace/g" "$f" 2>/dev/null || sed -E -i "s/$find/$replace/g" "$f"
                        else
                            sed -i "s/$(printf '%s' "$find" | sed -e 's/[\/&]/\\&/g')/$(printf '%s' "$replace" | sed -e 's/[\/&]/\\&/g')/g" "$f"
                        fi

                        ((count_done++))
                        # simple progress print
                        echo -ne "${GREEN}[$count_done/$total]${RESET} processed\r"
                    done
                    echo ""
                    echo -e "${GREEN}Replaced ALL successfully! Backup snapshot: ${SNAPSHOT_DIR}${RESET}"
                else
                    echo -e "${RED}Canceled.${RESET}"
                    rmdir --ignore-fail-on-non-empty "$SNAPSHOT_DIR" 2>/dev/null || true
                fi
            else
                echo -e "${RED}Invalid choice.${RESET}"
                rmdir --ignore-fail-on-non-empty "$SNAPSHOT_DIR" 2>/dev/null || true
            fi
            ;;

        backups)
            echo -e "${GREEN}Available backups:${RESET}"
            if [ ! -d "$BACKUP_ROOT" ]; then
                echo "No backups."
                continue
            fi
            ls -1 "$BACKUP_ROOT" | sed -n '1,200p'
            echo ""
            ;;

        undo)
            # list backups
            echo -e "${BLUE}[renameku]${RESET} Available backup snapshots:"
            mapfile -t snaps < <(ls -1 "$BACKUP_ROOT" 2>/dev/null)
            if [ ${#snaps[@]} -eq 0 ]; then
                echo -e "${RED}No backups available.${RESET}"
                continue
            fi
            i=1
            for s in "${snaps[@]}"; do
                echo -e "${YELLOW}$i.${RESET} $s"
                ((i++))
            done
            echo -ne "${BLUE}[renameku]${RESET} Choose snapshot number to restore (or 'cancel'): "
            read pick
            if [[ "$pick" =~ ^[Cc]ancel$ ]]; then
                echo "Canceled."
                continue
            fi
            if ! [[ "$pick" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Invalid choice.${RESET}"
                continue
            fi
            idx=$((pick-1))
            if [ $idx -lt 0 ] || [ $idx -ge ${#snaps[@]} ]; then
                echo -e "${RED}Invalid number.${RESET}"
                continue
            fi
            SNAP="${snaps[$idx]}"
            SNAPDIR="$BACKUP_ROOT/$SNAP"
            echo -ne "${BLUE}[renameku]${RESET} This will overwrite current files with the backup. Continue? Y/N: "
            read ok
            if [[ "$ok" =~ ^[Yy]$ ]]; then
                # copy files back
                echo "Restoring..."
                rsync -a --remove-source-files "$SNAPDIR"/ . || cp -a "$SNAPDIR"/. .
                echo -e "${GREEN}Restore complete from $SNAPDIR${RESET}"
            else
                echo "Restore canceled."
            fi
            ;;

        download)
            echo -ne "${BLUE}[renameku]${RESET} direct link : "
            read link
            echo -e "${BLUE}[renameku]${RESET} downloading..."
            wget "$link"
            echo -e "${GREEN}Download complete!${RESET}"
            ;;

        ls)
            ls --color=auto
            ;;

        cd)
            if [ -z "$args" ]; then
                echo -e "${RED}Usage: cd <path>${RESET}"
            else
                cd "$args" || echo -e "${RED}Path not found${RESET}"
            fi
            ;;

        open)
            if [ -z "$args" ]; then
                echo -e "${RED}Usage: open <filename>${RESET}"
            else
                if [ ! -f "$args" ]; then
                    echo -e "${RED}File not found${RESET}"
                else
                    # show file with line numbers
                    nl -ba "$args" | sed -n '1,200p'
                fi
            fi
            ;;

        clear)
            clear
            ;;

        exit)
            echo -e "${BLUE}[renameku]${RESET} bye!"
            exit
            ;;

        "")
            ;;

        *)
            echo -e "${RED}Unknown command:${RESET} $cmd"
            echo "Type 'help' to see command list"
            ;;
    esac
done
