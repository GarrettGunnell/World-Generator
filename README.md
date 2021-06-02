# Terrain Generator
by Garrett Gunnell

## Goals
* Generate interesting, unique height maps for use in other projects
* Utilize several different techniques for generating terrain
* Understand how to make use of the gradient of noise functions
* Experiment with different terrain shading techniques from toon to physically based
* Learn how skyboxes work

### Examples

Terrain: <br>
![Terrain](https://puu.sh/HLN5w.png)

Map: <br>
![Height Map](https://puu.sh/HLNF5.png)
Displacement value is in the red channel, while the *x* and *z* components of the gradient are stored in the green and blue channels such that the normal can be reconstructed in the shader.

### Resources
https://iquilezles.org/www/index.htm <br>
https://www.decarpentier.nl/scape-procedural-extensions <br>
https://www.youtube.com/watch?v=C9RyEiEzMiU&ab_channel=GDC