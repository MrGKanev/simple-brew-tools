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

# Function to list all installed Homebrew programs and save to a file
list_installed_programs() {
  echo "Listing all installed Homebrew programs..."
  brew list > brew_programs_list.txt
  echo "Programs have been listed in brew_programs_list.txt"
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
  echo "Updating all installed Homebrew programs..."
  brew update && brew upgrade
  if [ $? -eq 0 ]; then
    echo "All programs updated successfully."
  else
    echo "Failed to update some programs. Check the errors above."
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

# Menu picker
echo "Brew Simple tools"
echo "Select an option:"
echo "1. Install Homebrew"
echo "2. Make a list of all installed Homebrew programs"
echo "3. Install programs from brew_programs_list.txt"
echo "4. Uninstall programs from brew_programs_list.txt"
echo "5. Update all installed Homebrew programs"
echo "6. Check Homebrew health"
echo "7. Clean up Homebrew"
read -p "Enter your choice [1-7]: " choice

case $choice in
  1)
    install_homebrew
    ;;
  2)
    list_installed_programs
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
    check_brew_health
    ;;
  7)
    cleanup_brew
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
