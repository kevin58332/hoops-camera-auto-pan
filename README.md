# hoops-camera-auto-pan
Small app developed in swift using yoloV5s to track people in the camera view and pan to the average location of all the people. 

# Workflow

input: 4k ultra wide camera on iPhone

input as video -> individual frame is resized to optimal dimensions (640 x 640) -> frame is fed into model to detect people -> model outpus bounding box location of all the people in the frame -> average x position is calculated of all the people detected (this will likely be changed, just a starting point) -> using a scrollview, pan to the position found in the previous step

ex:
~~~text
                           <- 3840 px ->
____________________________________________________________________________
|                                                                           |
|                                                    AV Preview Layer       |
|                                                                           |
|                           <- 1280px ->                                    |
|           _____________________________________________                   |
|          |                                            |                   |
|          |                                            |                   |     ^
|          |                                            |                   |     |
|          |                                            |  ^                |   2160 px
|          |            ScrollView                      |  |                |     |
|          |                                            |  720 px           |     v
|          |                                            |  |                |
|          |                                            |  v                |
|          |                                            |                   |
|          |____________________________________________|                   |
|                                                                           |
|                                                                           |
|                                                                           |
|___________________________________________________________________________|
                             
~~~

note: the scrollview fills the entire iPhone screen and the preview layer extens beyond the bounds of the screen.
