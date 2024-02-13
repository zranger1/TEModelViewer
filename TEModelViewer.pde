
import peasy.PeasyCam;
import me.walkerknapp.devolay.*;
import java.nio.ByteBuffer;
import static me.walkerknapp.devolay.DevolayReceiver.RECEIVE_BANDWIDTH_HIGHEST;


// Note: NDI source must be running before starting this sketch.
//
// Drag w/mouse to move camera,
// scroll wheel zooms in/out
// Double click to reset camera.
PeasyCam cam;

PShape particles;
PImage sprite;  

int npartTotal = 80000;
float partSize = 20;
float divisor = 10000;
LightModel l;

int fcount, lastm;
float frate;
int fint = 3;
float [][] teModel;

DevolayFinder finder;
DevolayReceiver ndiIn;
DevolayVideoFrame ndiFrame;


void loadTEModel() {

  Table table = loadTable("TEPoints.csv", "header");

  println(table.getRowCount() + " total rows in table");
  
  teModel = new float[3][table.getRowCount()]; 

  int n = 0;
  for (TableRow row : table.rows()) {
    teModel[0][n] = row.getFloat("xn");
    teModel[1][n] = -row.getFloat("yn");
    teModel[2][n] = row.getFloat("zn");
    n++;
  }
  
  npartTotal = table.getRowCount();
}

void findAndConnect() {  

   DevolaySource[] sources;
   while ((sources = finder.getCurrentSources()).length == 0) {
      // If none found, wait until the list changes
        println("Waiting for sources...");
        finder.waitForSources(3000);
    }

    // Connect to the first source found
    // TODO - should probably connect by name.
    println("Connecting to source: " + sources[0].getSourceName());
    ndiIn.connect(sources[0]);
}


void setup() {
  // set the window size
  size(1280,800, P3D);
  // ...or, to go fullscreen on the default monitor
  // fullScreen(P3D,0);
  frameRate(60);
  blendMode(ADD);
  
  cam = new PeasyCam(this, 0,-400,0,2000);
  
  Devolay.loadLibraries();
   
  finder = new DevolayFinder();
 
      ndiIn =
          new DevolayReceiver( DevolayReceiver.ColorFormat.BGRX_BGRA, RECEIVE_BANDWIDTH_HIGHEST, false, "Projector");  
  
  ndiFrame = new DevolayVideoFrame();  

  l = new LightModel(0,0,50,32,ledTypes.BULB);
  particles = createShape(PShape.GROUP);
  sprite = l.diode;
  
  loadTEModel();

  // for each LED, scale point values down a bit and create a sprite
  for (int n = 0; n < npartTotal; n++) {
    float cx = teModel[2][n] / divisor;
    float cy = teModel[1][n] / divisor; 
    float cz = teModel[0][n] / divisor;
    
    PShape part = createShape();
    part.beginShape(QUAD);
    part.noStroke();
    part.tint(color(random(255),random(255),random(255)));
    part.texture(sprite);
    part.normal(0, 0, 1);
    part.vertex(cx - partSize/2, cy - partSize/2, cz, 0, 0);
    part.vertex(cx + partSize/2, cy - partSize/2, cz, sprite.width, 0);
    part.vertex(cx + partSize/2, cy + partSize/2, cz, sprite.width, sprite.height);
    part.vertex(cx - partSize/2, cy + partSize/2, cz, 0, sprite.height);    
    part.endShape(); 
    part.disableStyle();
    particles.addChild(part);
    part.disableStyle();
  }

  // Writing to the depth buffer is disabled to avoid rendering
  // artifacts due to the fact that the particles are semi-transparent
  // but not z-sorted.
  hint(DISABLE_DEPTH_MASK);
  //hint(ENABLE_DEPTH_SORT);
  
  findAndConnect(); 
} 

void draw () {
  background(0);
  
  if (DevolayFrameType.VIDEO == ndiIn.receiveCapture(ndiFrame, null, null, 250)) {
     ByteBuffer buffer = ndiFrame.getData();
     
  
  for (int n = 0; n < npartTotal; n++) {
      PShape ps = particles.getChild(n);
      ps.setTint(buffer.getInt(n * 4));
    }
  }     
     
  //translate(640,800,0);

  shape(particles); 
  
  fcount += 1;
  int m = millis();
  if (m - lastm > 1000 * fint) {
    frate = float(fcount) / fint;
    fcount = 0;
    lastm = m;
   // println("fps: " + frate); 
  }  
}
