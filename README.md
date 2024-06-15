

# SSHedit

<p align="center">
  <img src="" alt="SSHedit Logo">
</p>

<h1 align="center">SSHedit</h1>

SSHedit is a powerful tool that connects to your SSH server using a `.pem` file or password authentication. It automatically copies the entire file structure to your local machine with the current date, ensuring version control and backups. Additionally, SSHedit runs a file watcher to update files on the server in real-time as you make changes locally.

## Features
- **Automatic Version Control:** Back up your files with date-stamped copies.
- **Real-time Sync:** Instantly reflect local changes on the remote server.
- **Cross-Platform:** Supports both Unix-based systems and Windows.

## Installation and Usage

### Unix-based Systems

1. **Run the script:**
   ```bash
   sudo ./ssheditV2.sh
   ```

2. **Follow the GUI Prompts:**
   - **SSH Host:** Enter the IP address or hostname of the SSH server (e.g., `3.23.253.5`).
   - **Username:** Enter the SSH username (e.g., `ubuntu`).
   - **.pem File:** Choose the `.pem` file using the file chooser dialog.
   - **Remote Path:** Enter the remote file path (e.g., `/home/ubuntu/`).
   - **Code Editor:** Enter the shortcode for your code editor (e.g., `code` for VS Code, `subl` for Sublime Text).

### Windows

1. **Prepare PowerShell:**
   Open PowerShell in administrative mode and run:
   ```powershell
   Set-ExecutionPolicy Unrestricted
   ```

2. **Install 7-Zip:**
   Ensure `7zip` or `7z` is installed and available in your system's PATH.

3. **Run the Script:**
   The steps are the same as Unix-based systems, but the SSH host and other properties must be provided through `winssheditConfig.json`.

## Configuration

### winssheditConfig.json
Configure your SSH connection settings in the `winssheditConfig.json` file for Windows.

```json
{
  "host": "3.23.253.5",
  "username": "ubuntu",
  "pem_file": "path/to/your/key.pem",
  "remote_path": "/home/ubuntu/"
}
```

## Getting Started

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/KTBsomen/sshedit.git
   cd sshedit
   ```

2. **Run the Script:**
   Follow the installation steps for your operating system.

3. **Enjoy Seamless SSH Editing:**

   ![SSHedit Screenshot](https://github.com/KTBsomen/sshedit/assets/53004533/8f383ae6-38fd-4544-aef6-c44354c427ce)

## Troubleshooting

- Ensure you have the necessary permissions to execute scripts and access the SSH server.
- Verify that `7zip` or `7z` is installed and in your PATH on Windows.
- Check your network connection and SSH server accessibility.

## Contributing

We welcome contributions! Please read our [Contributing Guidelines](https://github.com/KTBsomen/sshedit/blob/main/CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/KTBsomen/sshedit/blob/main/LICENSE) file for more information.

---

Feel free to replace the placeholder URLs and images with actual resources. This version centers the project name and logo for a more polished look.
