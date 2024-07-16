#!/bin/bash

# Function to install Homebrew
install_homebrew() {
  if command -v brew &> /dev/null; then
    echo "Homebrew is already installed."
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if [ $? -eq 0 ]; then
      echo "Homebrew installed successfully."
    else
      echo "Failed to install Homebrew. Exiting."
      exit 1
    fi
  fi
}

# Function to backup installed programs and their versions
backup_installed_programs_and_versions() {
  echo "Backing up installed programs and their versions..."
  brew list --versions > brew_programs_backup.txt
  echo "Backup completed and saved to brew_programs_backup.txt"
}

# Function to install programs from brew_programs_list.txt
install_programs() {
  echo "Installing programs from brew_programs_list.txt..."
  while IFS= read -r program
  do
    echo "Checking if $program is already installed..."
    if brew list --formula | grep -q "^${program}\$"; then
      echo "$program is already installed. Skipping."
    else
      echo "Installing $program..."
      brew install "$program"
      if [ $? -eq 0 ]; then
        echo "$program installed successfully."
      else
        echo "Failed to install $program. Exiting."
        exit 1
      fi
    fi
  done < brew_programs_list.txt
  echo "All programs have been installed."
}

# Function to uninstall programs from a file
uninstall_programs() {
  echo "Uninstalling programs from brew_programs_list.txt..."
  while IFS= read -r program
  do
    echo "Checking if $program is installed..."
    if brew list --formula | grep -q "^${program}\$"; then
      echo "Uninstalling $program..."
      brew uninstall "$program"
      if [ $? -eq 0 ]; then
        echo "$program uninstalled successfully."
      else
        echo "Failed to uninstall $program. Exiting."
        exit 1
      fi
    else
      echo "$program is not installed. Skipping."
    fi
  done < brew_programs_list.txt
  echo "All listed programs have been processed."
}

# Function to update all installed Homebrew programs
update_programs() {
  backup_installed_programs_and_versions
  echo "Updating all installed Homebrew programs..."
  brew update && brew upgrade
  if [ $? -eq 0 ]; then
    echo "All programs updated successfully."
  else
    echo "Failed to update some programs. Check the errors above."
  fi
}

# Function to rollback updates to previous versions
rollback_updates() {
  if [ -f brew_programs_backup.txt ]; then
    echo "Rolling back to previous versions..."
    while IFS= read -r line
    do
      program=$(echo "$line" | awk '{print $1}')
      version=$(echo "$line" | awk '{print $2}')
      echo "Reinstalling $program@$version..."
      brew uninstall "$program"
      brew install "$program@$version"
      if [ $? -eq 0 ]; then
        echo "$program@$version installed successfully."
      else
        echo "Failed to reinstall $program@$version. Exiting."
        exit 1
      fi
    done < brew_programs_backup.txt
    echo "Rollback completed."
  else
    echo "No backup file found. Cannot rollback updates. Exiting."
    exit 1
  fi
}

# Function to check Homebrew health
check_brew_health() {
  echo "Checking Homebrew health..."
  brew doctor
}

# Function to clean up Homebrew
cleanup_brew() {
  echo "Cleaning up Homebrew..."
  brew cleanup
  if [ $? -eq 0 ]; then
    echo "Homebrew cleaned up successfully."
  else
    echo "Failed to clean up Homebrew. Check the errors above."
  fi
}

# Function to search for a Homebrew package
search_package() {
  read -p "Enter the name of the package to search: " package
  brew search "$package"
}

# Function to list outdated Homebrew packages
list_outdated_packages() {
  echo "Listing all outdated Homebrew packages..."
  brew outdated
}

# Menu picker
echo "Select an option:"
echo "1. Install Homebrew"
echo "2. Backup installed programs and their versions"
echo "3. Install programs from brew_programs_list.txt"
echo "4. Uninstall programs from brew_programs_list.txt"
echo "5. Update all installed Homebrew programs"
echo "6. Rollback updates to previous versions"
echo "7. Check Homebrew health"
echo "8. Clean up Homebrew"
echo "9. Search for a Homebrew package"
echo "10. List outdated Homebrew packages"
read -p "Enter your choice [1-10]: " choice

case $choice in
  1)
    install_homebrew
    ;;
  2)
    backup_installed_programs_and_versions
    ;;
  3)
    install_programs
    ;;
  4)
    uninstall_programs
    ;;
  5)
    update_programs
    ;;
  6)
    rollback_updates
    ;;
  7)
    check_brew_health
    ;;
  8)
    cleanup_brew
    ;;
  9)
    search_package
    ;;
  10)
    list_outdated_packages
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac