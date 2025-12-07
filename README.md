# RenameKu – Terminal Bulk Rename & Replace CLI Tool

RenameKu is a lightweight interactive CLI tool for Termux that allows you to:
- Rename text inside a single file  
- Replace multiple files' content inside a folder  
- Download files from direct links  
- And more commands (listed in the Help section)

RenameKu is built for fast development workflows similar to VSCode's search & replace, but directly inside Termux.


---

## 🛠 Installation

Update packages (optional but recommended):

```sh
apt update
apt upgrade
```

Clone this repository:

```sh
git clone https://github.com/kurobytesmrt/renameku
```

Enter the project directory:

```sh
cd renameku
```

Give execute permission:

```sh
chmod +x renameku.tmux
```

Run the tool:

```sh
./renameku.tmux
```


---

## 🚀 Usage

After running the script, you will see:

```
You Entered RenameKu - Project
[renameku]
```

From here, you can type available commands.


---

## 📌 Commands Overview

### **1. help**
Displays all available commands:

```
help
```

### **2. rename**
Rename text inside a single file.

```
rename
```

You will be asked:

```
Enter file path:
Find:
Replace:
```

If matches are found:

```
File: example.txt
Line 24 → replaced
Line 55 → replaced
Y to confirm, N to cancel:
```

### **3. renameall**
Search & replace across ALL FILES inside a folder.

```
renameall
```

You will be asked:

```
Enter folder path:
Find:
Replace:
```

Shows preview:

```
Found matches:
./app/main.js (5 matches)
./src/utils/helper.js (2 matches)
./config/system.json (1 match)

Options:
Y → Replace this file only
U → Replace ALL files
N → Cancel
```

If selecting **U**:

```
Are you sure you want to replace all? (Y/N)
```

Success output:

```
✔ Successfully replaced 8 occurrences in 3 files.
```


### **4. download**
Download any file from a direct link.

```
download
```

Then you will be asked:

```
Enter the direct link:
```

File will be saved automatically into the RenameKu directory.


---

## 🧪 Example Output (Preview)

```
You Entered RenameKu - Project
[renameku] renameall
Enter folder path: src
Find: token
Replace: api_token

Found matches:
src/app.js (3)
src/core/main.js (1)
src/lib/request.js (2)

U → Replace all
Y → Replace one
N → Cancel

U
Are you sure? (Y/N): Y

✔ Replacement completed.
✔ 6 occurrences replaced across 3 files.
```

---

## 📄 License
MIT License – free to use & modify.

---

## ⭐ Contributions
Pull requests are welcome.  
If you want new commands added, feel free to open an issue.

---

If you want this formatted differently (emoji-style, more minimalist, or more professional), tinggal bilang aja co.
