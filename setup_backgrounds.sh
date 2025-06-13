#!/bin/bash

# Create the assets/images directory if it doesn't exist
mkdir -p assets/images

# Check if the background images exist in the root directory
if [ -f "light_background.png" ] && [ -f "dark_background.png" ]; then
  echo "Moving background images to assets/images/"
  mv light_background.png dark_background.png assets/images/
  echo "Done!"
elif [ -f "light_background.png" ] || [ -f "dark_background.png" ]; then
  echo "Error: Only one background image found. Please make sure both light_background.png and dark_background.png are in the root directory."
  exit 1
else
  echo "Please place your light_background.png and dark_background.png files in the root directory and run this script again."
  echo "The images will be moved to the assets/images/ directory."
  exit 1
fi
