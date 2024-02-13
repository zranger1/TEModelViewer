enum ledTypes {
  BULB,
  SMD
}

class LightModel {
  float x,y;
  PGraphics lightMap;
  PGraphics led;
  PGraphics diode;
  ledTypes type;
  
  LightModel(float x, float y, float scale,float lightLevel, ledTypes type) {
    this.x = x;
    this.y = y;
    this.type = type;
    lightMap = buildLightMap(scale * 4,2);
    diode = buildLightMap(scale,2);          

    switch (type) {
      case BULB:
       led = buildBulbModel(scale,lightLevel);      
        break;
      case SMD:     
        led = buildSMDModel(scale,lightLevel);      
        break;     
    }
  }
  
  void draw(int col) {
    float bri;
    int hCol;
    pushMatrix();    
    translate(x,y,0);
    
    bri = (float) brightness(col) / 255.0;
    if (bri < 0.005) {
       col = color(10);
       hCol = color(0);
    }
    else {
      bri = max(0.4,bri);
      float h = hue(col);
      float s = saturation(col);
      colorMode(HSB,255);
      hCol = color(h,s,255 * bri);
      colorMode(RGB,255);
      
      emissive(col);
      tint(col);
      image(lightMap,0,0);       
    }

    noTint();  
    emissive(col);
    image(led,0,0);
    
    emissive(hCol);
    tint(hCol);
    image(diode,0,0,diode.width * 2,diode.height * 2);
    
    popMatrix();    
  } 
  
  PGraphics buildBulbModel(float mapSize,float lit) {
    PGraphics pg;
    PShape base;

    base = createShape(ELLIPSE,0,0,mapSize,mapSize);
    base.setFill(color(lit*0.8));
    base.translate(0,0,-(mapSize / 6));
    base.disableStyle();
    
    pg = createGraphics((int) mapSize,(int) mapSize,PConstants.P3D);
    pg.smooth(8);
    
    pg.beginDraw();
    pg.translate(mapSize / 2, mapSize / 2,0);
    pg.background(0,0,0,0);        
    pg.noStroke();
    pg.ellipseMode(CENTER);

    pg.fill(lit);
    pg.sphereDetail(60);
    
    pg.shininess(50);
    pg.emissive(color(lit/2));
    pg.ambient(0,0,0);
    pg.lightSpecular(255, 255, 255);    
    pg.directionalLight(lit, lit, lit, 2.25, 2, -1);    
    pg.specular(100);
    
    pg.shape(base);
    pg.sphere(mapSize * 0.3125);
        
    pg.endDraw();
    return pg;    
  }  
  
  PGraphics buildSMDModel(float mapSize,float lit) {
    PGraphics pg;
    float s,v;
    float scaledStroke = 0.015625 * mapSize;  // 1/64 of the map size
       
    pg = createGraphics((int) mapSize,(int) mapSize,PConstants.P3D);
    
    pg.beginDraw();    
    pg.background(0,0,0,0);
    pg.imageMode(CENTER);
    pg.ellipseMode(CENTER);
    pg.rectMode(CENTER);    
    pg.translate(mapSize / 2, mapSize / 2);  
            
    s = mapSize * 0.775;
    
    // draw square SMD frame
    pg.noStroke();
    pg.fill(color(lit * 0.6));    
    pg.square(0,0,s);
    
    // 3D highlighting on top and left edges
    pg.stroke(color(lit));
    pg.strokeWeight(scaledStroke);
    v = s / 2;
    pg.line(-v,-v,v,-v);
    pg.line(-v,v,-v,-v);
   
    s *= 0.875;

    // elliptical area at center of SMD
    pg.shininess(100);
    pg.fill(color(lit * 0.75));
    pg.strokeWeight(scaledStroke);
    pg.stroke(color(lit));
    pg.ellipse(0,0,s,s * 0.9);
    
    pg.noFill();
    pg.strokeWeight(scaledStroke);
    pg.stroke(color(lit * 0.25));
    v = s - scaledStroke * 0.9;    
    pg.ellipse(0,0,v,v * 0.9);       
    
    // fake wiring!
    s /= 2;   
    s *= 0.8;      
    float cDark = lit * 0.25;
    float cLight = lit * 0.8;
    pg.strokeWeight(scaledStroke);
    pg.stroke(color(cDark));
    pg.line(scaledStroke/2.25,0,scaledStroke/2.25,-s);
    pg.stroke(color(cLight));
    pg.line(0,0,0,-s);
    
    s *= 0.725;  
    v = s + scaledStroke / 2;
    pg.stroke(color(cDark));    
    pg.line(-scaledStroke / 2,0,-v,s);    
    pg.stroke(color(cLight));    
    pg.line(0,0,-s,s);
    
    pg.stroke(color(cDark)); 
    pg.line(scaledStroke / 2,0,v,s);
    pg.stroke(color(cLight));    
    pg.line(0,0,s,s);
    
    pg.noStroke();
    pg.fill(color(lit));
    pg.emissive(color(lit));
    pg.circle(0,0,scaledStroke * 5);
        
    pg.endDraw();
    return pg; 
  } 
  
  // map of inverse power law-based light falloff around LED
  PGraphics buildLightMap(float mapSize,float falloff) {
    PGraphics pg;

    pg = createGraphics((int) mapSize,(int) mapSize,PConstants.P3D);
    pg.smooth(8);

    pg.beginDraw();
    pg.imageMode(CENTER);
    pg.shininess(100);
    pg.specular(color(255));    
    
    setFalloffModel(pg,0,0,mapSize,falloff);

    pg.endDraw();
    return pg;
  }
  
  // takes a PGraphics object on which beginDraw() has been called, and fills it
  // with a regional light map that falls off at the specified rate
  void setFalloffModel(PGraphics pg,int xst, int yst, float mapSize,float falloff) {
    int x,y;
    float cx,cy,dx,dy,dist,maxDist;
    float alpha;

    dx = mapSize / 2;
    maxDist = sqrt(dx * dx + dx * dx);
    cx = xst + dx;
    cy = yst + dx;
       
    for (y = 0; y < mapSize; y++) {
      for (x = 0; x < mapSize; x++) {

        dx = (float) (x+xst) - cx;
        dy = (float) (y+yst) - cy;
        dist = (float) Math.sqrt(dx * dx + dy * dy);
        dist = (float) Math.max(0,1-(dist/maxDist));
        alpha = (float) (255 * Math.pow(dist,falloff));
        dist = (float) (255 * Math.pow(dist,falloff));
        pg.set(x+xst,y+yst,color(dist,dist,dist,alpha));
      }      
    }      
  }   
};
