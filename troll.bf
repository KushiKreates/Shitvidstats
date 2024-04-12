,           // Input a character
[           // Start of loop
  -         // Decrement the input character
  >         // Move to the next cell
]           // End of loop
<           // Move back to the original cell
[           // Start of loop
  >         // Move to the next cell
  .         // Output the character
  <         // Move back to the original cell
]           // End of loop
