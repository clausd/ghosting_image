/*   Ghosts  - averaged webcam images
 *   Exponential averaging of webcam images
 *
 *   Controls: 
 *   press s: new information means less, old information stays in longer
 *             - less visible ghosts, but longer lasting
 *             - minimal value: The image is just a still
 *   press f: new information means more, old forgotten sooner.
 *             - shorter, more visible ghosts
 *             - maximum value: The image is just the webcam image
 *
 *   press d: Toggle between seeing the image, and just a measure of differences
 *
 *   press r: Toggle video recording. Each recording becomes a separate file - left in the root directory of the sketch
 *
 *   press c: To show the weighted center of the deviations in the deviation image mode
 *
 */
import processing.video.*;

Capture video;
MovieMaker mm;

// controls how slow or fast changes are forgotten. Higher is faster. 0 < alfa < 1
// note: slowly forgotten = less visible also
float alfa = 0.09;
float[] r_avg = new float[800*600];
float[] g_avg = new float[800*600];
float[] b_avg = new float[800*600];
float[] r_dev = new float[800*600];
float[] g_dev = new float[800*600];
float[] b_dev = new float[800*600];

boolean show_diffs = false;
boolean show_diff_center = false;
boolean recording = false;


void setup() {
   size(800,600); 
   frameRate(6);
   video = new Capture(this, width, height, 6);
}

void keyPressed() {
  if (key == 'd') {
    show_diffs = !show_diffs;
  }
  if (key == 'c') {
    show_diff_center = !show_diff_center; 
  }
  if (key == 's') {
    alfa = max(alfa-0.01,0);
  }
  if (key == 'f') {
    alfa = min(alfa+0.01,1);
  }
  if (key == 'r') {
    recording = !recording;
    if (recording) {
      mm = new MovieMaker(this, width, height, 
        "ghosts_" + year() + "_" + month() + "_" + day() + "_" + hour() + "_" + minute() + "_" + second() + ".mov",6, MovieMaker.H263,MovieMaker.LOSSLESS);
    }
    if (!recording) {
      mm.finish();
    }
  }
}

void draw() {
  if (video.available()) {
    video.read();
    PImage overlay = createImage(width,height,RGB);
    video.loadPixels();
    int index = 0;
    float total_deviation = 0;
    float center_diff_x = 0;
    float center_diff_y = 0;
    float diff_sum = 0;
    
    for (int y = 0; y < video.height; y++) {
      for (int x = 0; x < video.width; x++) {
        // Get the color stored in the pixel
        int pixelValue = video.pixels[index];
        // Determine the brightness of the pixel
        float p_r = red(pixelValue);
        float p_g = green(pixelValue);
        float p_b = blue(pixelValue);
        
        // computing statistics 
        r_avg[index] = exp_avg(p_r,r_avg[index]);
        g_avg[index] = exp_avg(p_g,g_avg[index]);
        b_avg[index] = exp_avg(p_b,b_avg[index]);
        total_deviation = total_deviation + abs(r_avg[index]-p_r) + abs(g_avg[index]-p_g) + abs(b_avg[index]-p_b);
        
        r_dev[index] = exp_deviation(p_r,r_avg[index],r_dev[index]);        
        g_dev[index] = exp_deviation(p_r,g_avg[index],g_dev[index]);        
        b_dev[index] = exp_deviation(p_b,b_avg[index],b_dev[index]);
        center_diff_x = center_diff_x + (r_dev[index] + g_dev[index] + b_dev[index])*x;
        center_diff_y = center_diff_y + (r_dev[index] + g_dev[index] + b_dev[index])*y;
        diff_sum = diff_sum + r_dev[index] + g_dev[index] + b_dev[index];
        if (show_diffs) {
          overlay.pixels[index] = color(r_dev[index] + g_dev[index] + b_dev[index], 
                                        r_dev[index] + g_dev[index] + b_dev[index]);
        } else {
          overlay.pixels[index] = color(r_avg[index], g_avg[index], b_avg[index]);
        }
        index++;
      }
    }
    //image(video,0,0,width,height);
    image(overlay,0,0,width,height);
    if (show_diffs && show_diff_center) {
      stroke(color(0,200,0));
      fill(color(0,200,0));
      ellipse(center_diff_x/diff_sum,center_diff_y/diff_sum,20,20);
    }
    if (recording) {
      mm.addFrame();
      stroke(color(200,0,0));
      fill(color(200,0,0));
      ellipse(30,30,20,20);
    }
    println(total_deviation);
  }
}

float exp_avg(float value, float last_avg) {
    return alfa*value+(1-alfa)*last_avg; 
}

float exp_deviation(float value, float exp_avg, float last_dev) {
    return exp_avg(abs(value-exp_avg),last_dev);
}


