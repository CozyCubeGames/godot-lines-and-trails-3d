[Godot Lines & Trails 3D]

Info:
Just a basic lines and trails addon used in my own project.
This addon is provided as is. There will be no support, but I will be making changes to this as I develop my own project.

Usage:
Just put it in your addons folder in your project, and then you can create Line3D or Trail3D nodes.
You can choose from three different default materials, or you can create your own material that uses one of the three provided shaders.
Only use the material override to set material, do NOT use the surface material override or set the material directly on the mesh.
At runtime, you can modify the points array, or any other properties.
Line3D requires you to call rebuild() after making any changes. Trail3D is auto-updated so you don't need to call rebuild().

Tips and Tricks:
It doesn't currently handle sharp corners well (can get "pinched" at certain viewing angles). A workaround is to just duplicate the points at the corners.
