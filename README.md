# Plumbline

Fast, zero-allocation spatial debugger and raycast visualizer for Roblox.

I built Plumbline out of sheer frustration. For a long time, every time I needed to debug a melee hitbox, check an NPC's line of sight, or calculate a bullet ricochet, I had to write a dozen lines of code to spawn a temporary translucent red part. Doing that 60 times a second tanked my framerate, bloated my memory with garbage collection, and made my workspace an absolute mess. I just wanted a way to see my math in 3D space instantly without paying a massive physics cost. 

Plumbline is a high-performance, zero-allocation spatial debugging library for Roblox. It relies on a recyclable pool of HandleAdornment objects, meaning you can draw hundreds of hitboxes, rays, and physics arcs every single frame without dropping your framerate or waking up the physics engine. When you are ready to publish your game, you just flip `Plumbline.Enabled = false` and all the visualizers bypass execution, costing exactly zero performance in live servers.

### Core API Overview

* **Rays & Vectors:** `Plumbline.Ray`, `Plumbline.Arrow`, `Plumbline.Line` 
  Instantly draw bullet paths, read surface normals, and visualize reflective bounces.
* **Volumes & Hitboxes:** `Plumbline.Box`, `Plumbline.Sphere`, `Plumbline.Point` 
  Visualize melee swings, explosion radiuses, and static trigger zones.
* **Swept Shapecasts:** `Plumbline.Blockcast`, `Plumbline.Spherecast` 
  Render exactly where your thick dashes and projectiles start, travel, and eventually collide.
* **Advanced Gizmos:** 
  * `Plumbline.Trajectory`: Predict and draw multi-bounce parabolic physics arcs for grenades and ballistics.
  * `Plumbline.Cone`: Draw 3D radar cones to debug NPC stealth fields, flashlights, and vision angles.
  * `Plumbline.Axes`: Spawn a professional XYZ coordinate gizmo to debug CFrame orientation and local space relative to moving parts.

*(Full documentation and deep-dive examples will be available in the upcoming web documentation).*