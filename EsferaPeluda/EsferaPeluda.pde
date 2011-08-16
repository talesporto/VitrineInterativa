/**
 * Esfera
 * by David Pena.  
 * 
 * Distribucion aleatoria uniforme sobre la superficie de una esfera. 
 */

import processing.opengl.*;
import org.openkinect.*;
import org.openkinect.processing.*;


int cuantos = 8000;
Pelo[] lista ;
float[] z = new float[cuantos]; 
float[] phi = new float[cuantos]; 
float[] largos = new float[cuantos]; 
float radio = 200;
float rx = 0;
float ry =0;

// Showing how we can farm all the kinect stuff out to a separate class
KinectTracker tracker;
// Kinect Library object
Kinect kinect;

void setup() {
  size(640, 480, OPENGL);
  radio = height/3.5;
  
  lista = new Pelo[cuantos];
  for (int i=0; i<cuantos; i++){
    lista[i] = new Pelo();
  }
  noiseDetail(3);
  
  kinect = new Kinect(this);
  tracker = new KinectTracker();

}

void draw() {
  background(0);
  translate(width/2,height/2);

  tracker.track();
  tracker.display();

  // Let's draw the raw location
  PVector vPos = tracker.getPos();
  PVector vLerpedPos = tracker.getLerpedPos();
  float rxp = (((vLerpedPos.x)-(width/2))*0.005);
  float ryp = (((vLerpedPos.y)-(height/2))*0.005);
//  float rxp = ((mouseX-(width/2))*0.005);
//  float ryp = ((mouseY-(height/2))*0.005);
  
  rx = (rx*0.7)+(rxp*0.3);
  ry = (ry*0.7)+(ryp*0.3);
  rotateY(rx);
  rotateX(ry*-1);
  fill(0);
  noStroke();
  sphere(radio);

  for (int i=0;i<cuantos;i++){
    lista[i].dibujar();
  }
  
  println("vPos = x -> " + vPos.x + " y -> " +  vPos.y);
  println("vLerpedPos = x -> " + vLerpedPos.x + " y -> " +  vLerpedPos.y);
}

void stop() {
  tracker.quit();
  super.stop();
}


class Pelo {
  float z = random(-radio,radio);
  float phi = random(TWO_PI);
  float largo = random(1.15,1.2);
  float theta = asin(z/radio);

    void dibujar(){

    float off = (noise(millis() * 0.0005,sin(phi))-0.5) * 0.3;
    float offb = (noise(millis() * 0.0007,sin(z) * 0.01)-0.5) * 0.3;

    float thetaff = theta+off;
    float phff = phi+offb;
    float x = radio * cos(theta) * cos(phi);
    float y = radio * cos(theta) * sin(phi);
    float z = radio * sin(theta);
    float msx= screenX(x,y,z);
    float msy= screenY(x,y,z);

    float xo = radio * cos(thetaff) * cos(phff);
    float yo = radio * cos(thetaff) * sin(phff);
    float zo = radio * sin(thetaff);

    float xb = xo * largo;
    float yb = yo * largo;
    float zb = zo * largo;
    
    beginShape(LINES);
    stroke(0);
    vertex(x,y,z);
    stroke(200,150);
    vertex(xb,yb,zb);
    endShape();
  }
}

class KinectTracker {

  // Size of kinect image
  int kw = 640;
  int kh = 480;
  int minThreshold = 50;
  int threshold = 800;

  // Raw location
  PVector loc;

  // Interpolated location
  PVector lerpedLoc;

  // Depth data
  int[] depth;

  // Last depth data
  int[] lastDepth;

  PImage display;

  KinectTracker() {
    kinect.start();
    kinect.enableDepth(true);

    // We could skip processing the grayscale image for efficiency
    // but this example is just demonstrating everything
    kinect.processDepthImage(true);

    display = createImage(kw,kh,PConstants.RGB);

    loc = new PVector(0,0);
    lerpedLoc = new PVector(0,0);
  }

  void track() {

    // Get the raw depth as array of integers
    depth = kinect.getRawDepth();

    // Being overly cautious here
    if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;

    for(int x = 0; x < kw; x++) {
      for(int y = 0; y < kh; y++) {
        // Mirroring the image
        int offset = kw-x-1+y*kw;
        // Grabbing the raw depth
        int rawDepth = 0;

        rawDepth = depth[offset];

//        if(lastDepth == null) {
//          rawDepth = depth[offset];
//        } else if((depth[offset] - lastDepth[offset]) > 550) {
//          rawDepth = depth[offset] - lastDepth[offset];
//        }

        // Testing against threshold
        if (rawDepth > minThreshold && rawDepth < threshold) {
          sumX += x;
          sumY += y;
          count++;
        }
      }
    }
    // As long as we found something
    if (count != 0) {
      loc = new PVector(sumX/count,sumY/count);
    }

    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.x = PApplet.lerp(lerpedLoc.x, loc.x, 0.3f);
    lerpedLoc.y = PApplet.lerp(lerpedLoc.y, loc.y, 0.3f);
    
    // Save last frame
    lastDepth = depth;
  }

  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }

  void display() {
    PImage img = kinect.getDepthImage();

    // Being overly cautious here
    if (depth == null || img == null) return;

    // Going to rewrite the depth image to show which pixels are in threshold
    // A lot of this is redundant, but this is just for demonstration purposes
    display.loadPixels();
    for(int x = 0; x < kw; x++) {
      for(int y = 0; y < kh; y++) {
        // mirroring image
        int offset = kw-x-1+y*kw;
        // Raw depth
        int rawDepth = depth[offset];

        int pix = x+y*display.width;
        if (rawDepth > minThreshold && rawDepth < threshold) {
          // A red color instead
          display.pixels[pix] = color(150,50,50);
        } else {
          display.pixels[pix] = img.pixels[offset];
        }
      }
    }
    display.updatePixels();

    // Draw the image
    image(display,0,0);
  }

  void quit() {
    kinect.quit();
  }

  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold =  t;
  }
}

