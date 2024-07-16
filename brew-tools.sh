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

# Menu picker
echo "Brew Simple tools"
echo "Select an option:"
echo "1. Install Homebrew"
echo "2. Make a list of all installed Homebrew programs"
echo "3. Install programs from brew_programs_list.txt"
read -p "Enter your choice [1, 2 or 3]: " choice

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
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
