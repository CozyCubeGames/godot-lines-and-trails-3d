[Godot Lines & Trails 3D]

Info:
Just a basic lines and trails addon used in my own project.
This addon is provided as is. There will be no support, but I will be making changes to this as I develop my own project.

Usage:
Just put it in your addons folder in your project, and then you can create Line3D or Trail3D nodes.
At runtime, you can modify the points property, or any other properties, then call rebuild() when you're done.

Tips and Tricks:
It doesn't currently handle sharp corners well (can get "pinched" at certain viewing angles). A workaround is to just duplicate the points at the corners.
