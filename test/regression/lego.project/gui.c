// Dezyne --- Dezyne command line tools
//
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "imotor.h"
#include "ilight.h"
#include "itouch.h"
#include "itimer_impl.h"
#include "timer.h"

#include "LegoBallSorter.h"

#include <dzn/runtime.h>
#include <dzn/locator.h>

#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <math.h>
#include <gtk/gtk.h>

#define max(a,b) (((a) (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))

#define GTK_MOTOR_MIN -10000
#define GTK_MOTOR_MAX 10000

static unsigned long
gettime ()
{
  struct timespec systemtime;

  clock_gettime (CLOCK_REALTIME, &systemtime);
  return (unsigned long) ((systemtime.tv_sec * 1000UL)
                          + (systemtime.tv_nsec / 1000000UL));
}

typedef struct
{
  dzn_meta_t meta;
  GtkSpinButton* button;
  
  int home;
  int end;
  double velocity;
  int target;
  unsigned long last_update;

} GtkMotor;
  
GtkMotor*
gtk_motor_new (char const* name, int home, int end)
{
  GtkMotor* self = (GtkMotor*)malloc (sizeof (GtkMotor));
  GtkAdjustment* adjustment
    = gtk_adjustment_new (0.0, GTK_MOTOR_MIN, GTK_MOTOR_MAX, 1.0, 0.0, 0.0);
  self->button = (GtkSpinButton*)gtk_spin_button_new (adjustment, 1.0, 0);

  self->meta.name = name;
  self->meta.parent = 0;

  self->home = home;
  self->end = end;
  self->target = 0;
  self->velocity = 0.5;
  self->last_update = gettime ();
  return self;
}

static int
sign (int i)
{
  return i < 0 ? -1 : 1;
}

int
gtk_motor_get_value (GtkMotor* self)
{
  return gtk_spin_button_get_value_as_int (self->button);
}

void
gtk_motor_set_value (GtkMotor* self, int v)
{
  gtk_spin_button_set_value (self->button, v);
}

typedef struct GtkLego GtkLego;

void
gtk_motor_update (GtkMotor* self, GtkLego* lego, void (*f)(GtkLego*, int))
{
  unsigned long now = gettime ();
  int ms = now - self->last_update;
  int position = sign (self->target)
    * min (abs (gtk_motor_get_value (self)
                + sign (self->target) * self->velocity * ms),
           abs (self->target));
  f (lego, position);
  gtk_motor_set_value (self, position);
  self->last_update = now;
}

typedef struct
{
  dzn_meta_t meta;
  GtkCheckButton* button;
} GtkSensor;

GtkSensor*
gtk_sensor_new (char const* name)
{
  GtkSensor* self = (GtkSensor*)malloc (sizeof (GtkSensor));
  self->button = (GtkCheckButton*)gtk_check_button_new_with_label (name);
  self->meta.name = name;
  self->meta.parent = 0;
  return self;
}

struct GtkLego
{
  GtkWindow*     window;

  GtkBox*        box_lego;

  GtkBox*        box_buttons;
  GtkButton*     button_calibrate;
  GtkButton*     button_operate;
  GtkButton*     button_stop;

  GtkBox*        box_input;
  GtkBox*        box_output;
  GtkBox*        box_stage;
  GtkBox*        box_stage_x;
  GtkBox*        box_stage_y;
  GtkBox*        box_robot;
  GtkBox*        box_truck;
  GtkBox*        box_trolley;
  GtkBox*        box_hoist;
  GtkBox*        box_gripper;

  // input
  GtkFrame*      frame_input;
  GtkMotor*      motor_input_feeder;
  GtkMotor*      motor_input_feedport;

  GtkSensor*     sensor_input_feeder;
  GtkSensor*     sensor_input_feedport;

  // output
  GtkFrame*      frame_output;
  GtkMotor*      motor_output_reject_track;
  GtkMotor*      motor_output_accept_track;

  GtkSensor*     sensor_output_reject;
  GtkSensor*     sensor_output_accept;

  // light
  GtkSensor*     sensor_light;

  // stage
  GtkFrame*      frame_stage;
  GtkFrame*      frame_stage_x;
  GtkMotor*      motor_stage_x;

  GtkSensor*     sensor_stage_x_home;
  GtkSensor*     sensor_stage_x_end;

  GtkFrame*      frame_stage_y;
  GtkMotor*      motor_stage_y;

  GtkSensor*     sensor_stage_y_home;
  GtkSensor*     sensor_stage_y_end;

  // robot
  GtkFrame*      frame_robot;
  // truck
  GtkFrame*      frame_truck;
  GtkMotor*      motor_truck;    //robot x axis, moves trolley

  GtkSensor*     sensor_truck_home;

  // trolley
  GtkFrame*      frame_trolley;
  GtkMotor*      motor_trolley;  //robot y axis, moves hoist
  GtkSensor*     sensor_trolley_end;

  // hoist
  GtkFrame*      frame_hoist;
  GtkMotor*      motor_hoist;    //robot z axis, moves gripper up and down
  GtkSensor*     sensor_hoist_end;

  // gripper
  GtkFrame*      frame_gripper;
  GtkMotor*      motor_gripper;  //robot r axis, opens and closes gripper
  GtkSensor*     sensor_gripper_end;
};
  
GtkLego*
gtk_lego_new ()
{
  GtkLego* self = (GtkLego*)malloc (sizeof (GtkLego));

  self->window = (GtkWindow*)gtk_window_new (GTK_WINDOW_TOPLEVEL);

  self->box_lego = (GtkBox*)gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 2);
  self->box_buttons = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->button_calibrate = (GtkButton*)gtk_button_new_with_label ("calibrate");
  self->button_operate = (GtkButton*)gtk_button_new_with_label ("operate");
  self->button_stop = (GtkButton*)gtk_button_new_with_label ("stop");
  self->box_input = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 2);
  self->box_output = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 2);
  self->box_stage = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 2);
  self->box_stage_x = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->box_stage_y = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->box_robot = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 2);
  self->box_truck = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->box_trolley = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->box_hoist = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->box_gripper = (GtkBox*)gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  self->frame_input = (GtkFrame*)gtk_frame_new ("input");
  self->motor_input_feeder = (GtkMotor*)gtk_motor_new ("ext:input_feeder", 0, 400);
  self->motor_input_feedport = (GtkMotor*)gtk_motor_new ("ext:input_feedport", 0, 0);
  self->sensor_input_feeder = (GtkSensor*)gtk_sensor_new ("ext:feeder");
  self->sensor_input_feedport = (GtkSensor*)gtk_sensor_new ("ext:feedport");
  self->frame_output = (GtkFrame*)gtk_frame_new ("output");
  self->motor_output_reject_track = (GtkMotor*)gtk_motor_new ("ext:output_reject_track", 0, 0);
  self->motor_output_accept_track = (GtkMotor*)gtk_motor_new ("ext:output_accept_track", 0, 0);
  self->sensor_output_reject = (GtkSensor*)gtk_sensor_new ("ext:reject");
  self->sensor_output_accept = (GtkSensor*)gtk_sensor_new ("ext:accept");
  self->sensor_light = (GtkSensor*)gtk_sensor_new ("ext:light");
  self->frame_stage = (GtkFrame*)gtk_frame_new ("stage");
  self->frame_stage_x = (GtkFrame*)gtk_frame_new ("x");
  self->motor_stage_x = (GtkMotor*)gtk_motor_new ("ext:stage_x",-100,500);
  self->sensor_stage_x_home = (GtkSensor*)gtk_sensor_new ("ext:home");
  self->sensor_stage_x_end = (GtkSensor*)gtk_sensor_new ("ext:end");
  self->frame_stage_y = (GtkFrame*)gtk_frame_new ("y");
  self->motor_stage_y = (GtkMotor*)gtk_motor_new ("ext:stage_y",-250, 250);
  self->sensor_stage_y_home = (GtkSensor*)gtk_sensor_new ("ext:home");
  self->sensor_stage_y_end = (GtkSensor*)gtk_sensor_new ("ext:end");
  self->frame_robot = (GtkFrame*)gtk_frame_new ("robot");
  self->frame_truck = (GtkFrame*)gtk_frame_new ("truck");
  self->motor_truck = (GtkMotor*)gtk_motor_new ("ext:truck",-200, 1000);
  self->sensor_truck_home = (GtkSensor*)gtk_sensor_new ("ext:home");
  //    self->sensor_truck_end = (GtkSensor*)gtk_sensor_new ("end");
  self->frame_trolley = (GtkFrame*)gtk_frame_new ("trolley");
  self->motor_trolley = (GtkMotor*)gtk_motor_new ("ext:trolley",0, 800);
  self->sensor_trolley_end = (GtkSensor*)gtk_sensor_new ("ext:end");
  self->frame_hoist = (GtkFrame*)gtk_frame_new ("hoist");
  self->motor_hoist = (GtkMotor*)gtk_motor_new ("ext:hoist",0, 400);
  self->sensor_hoist_end = (GtkSensor*)gtk_sensor_new ("ext:end");
  self->frame_gripper = (GtkFrame*)gtk_frame_new ("gripper");
  self->motor_gripper = (GtkMotor*)gtk_motor_new ("ext:gripper",0, -468);
  self->sensor_gripper_end = (GtkSensor*)gtk_sensor_new ("ext:end");

  gtk_widget_set_sensitive (GTK_WIDGET (self->sensor_light->button), false);

#if 0
  set_title ("Lego");
  set_border_width (10);
#endif

  gtk_container_add (GTK_CONTAINER (self->window), GTK_WIDGET (self->box_lego));

  gtk_box_pack_start (self->box_lego, GTK_WIDGET (self->box_buttons), true, true, 1);

  gtk_box_pack_start (self->box_buttons, GTK_WIDGET (self->button_calibrate), true, true, 1);
  gtk_box_pack_start (self->box_buttons, GTK_WIDGET (self->button_operate), true, true, 1);
  gtk_box_pack_start (self->box_buttons, GTK_WIDGET (self->button_stop), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_input), GTK_WIDGET (self->box_input));
  gtk_container_add (GTK_CONTAINER (self->frame_robot), GTK_WIDGET (self->box_robot));
  gtk_container_add (GTK_CONTAINER (self->frame_stage), GTK_WIDGET (self->box_stage));
  gtk_container_add (GTK_CONTAINER (self->frame_output), GTK_WIDGET (self->box_output));
  gtk_box_pack_start (self->box_lego, GTK_WIDGET (self->frame_input), true, true, 1);
  gtk_box_pack_start (self->box_lego, GTK_WIDGET (self->frame_robot), true, true, 1);
  gtk_box_pack_start (self->box_lego, GTK_WIDGET (self->frame_stage), true, true, 1);
  gtk_box_pack_start (self->box_lego, GTK_WIDGET (self->frame_output), true, true, 1);

  gtk_box_pack_start (self->box_input, GTK_WIDGET (self->motor_input_feeder->button), true, true, 1);
  gtk_box_pack_start (self->box_input, GTK_WIDGET (self->sensor_input_feeder->button), true, true, 1);
  gtk_box_pack_start (self->box_input, GTK_WIDGET (self->motor_input_feedport->button), true, true, 1);
  gtk_box_pack_start (self->box_input, GTK_WIDGET (self->sensor_input_feedport->button), true, true, 1);

  gtk_box_pack_start (self->box_output, GTK_WIDGET (self->motor_output_reject_track->button), true, true, 1);
  gtk_box_pack_start (self->box_output, GTK_WIDGET (self->sensor_output_reject->button), true, true, 1);
  gtk_box_pack_start (self->box_output, GTK_WIDGET (self->motor_output_accept_track->button), true, true, 1);
  gtk_box_pack_start (self->box_output, GTK_WIDGET (self->sensor_output_accept->button), true, true, 1);

  gtk_box_pack_start (self->box_stage, GTK_WIDGET (self->sensor_light->button), true, true, 1);
  gtk_box_pack_start (self->box_stage, GTK_WIDGET (self->frame_stage_x), true, true, 1);
  gtk_box_pack_start (self->box_stage, GTK_WIDGET (self->frame_stage_y), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_stage_x), GTK_WIDGET (self->box_stage_x));
  gtk_box_pack_start (self->box_stage_x, GTK_WIDGET (self->motor_stage_x->button), true, true, 1);
  gtk_box_pack_start (self->box_stage_x, GTK_WIDGET (self->sensor_stage_x_home->button), true, true, 1);
  gtk_box_pack_start (self->box_stage_x, GTK_WIDGET (self->sensor_stage_x_end->button), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_stage_y), GTK_WIDGET (self->box_stage_y));
  gtk_box_pack_start (self->box_stage_y, GTK_WIDGET (self->motor_stage_y->button), true, true, 1);
  gtk_box_pack_start (self->box_stage_y, GTK_WIDGET (self->sensor_stage_y_home->button), true, true, 1);
  gtk_box_pack_start (self->box_stage_y, GTK_WIDGET (self->sensor_stage_y_end->button), true, true, 1);

  //gtk_box_pack_start (self->box_robot, GTK_WIDGET (self->frame_robot->button), true, true, 1);
  gtk_box_pack_start (self->box_robot, GTK_WIDGET (self->frame_truck), true, true, 1);
  gtk_box_pack_start (self->box_robot, GTK_WIDGET (self->frame_trolley), true, true, 1);
  gtk_box_pack_start (self->box_robot, GTK_WIDGET (self->frame_hoist), true, true, 1);
  gtk_box_pack_start (self->box_robot, GTK_WIDGET (self->frame_gripper), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_truck), GTK_WIDGET (self->box_truck));
  gtk_box_pack_start (self->box_truck, GTK_WIDGET (self->motor_truck->button), true, true, 1);
  gtk_box_pack_start (self->box_truck, GTK_WIDGET (self->sensor_truck_home->button), true, true, 1);
  //gtk_box_pack_start (self->box_truck, GTK_WIDGET (self->sensor_truck_end->button), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_trolley), GTK_WIDGET (self->box_trolley));
  gtk_box_pack_start (self->box_trolley, GTK_WIDGET (self->motor_trolley->button), true, true, 1);
  gtk_box_pack_start (self->box_trolley, GTK_WIDGET (self->sensor_trolley_end->button), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_hoist), GTK_WIDGET (self->box_hoist));
  gtk_box_pack_start (self->box_hoist, GTK_WIDGET (self->motor_hoist->button), true, true, 1);
  gtk_box_pack_start (self->box_hoist, GTK_WIDGET (self->sensor_hoist_end->button), true, true, 1);

  gtk_container_add (GTK_CONTAINER (self->frame_gripper), GTK_WIDGET (self->box_gripper));
  gtk_box_pack_start (self->box_gripper, GTK_WIDGET (self->motor_gripper->button), true, true, 1);
  gtk_box_pack_start (self->box_gripper, GTK_WIDGET (self->sensor_gripper_end->button), true, true, 1);

  gtk_widget_show_all (GTK_WIDGET (self->window));
  return self;
}

void
dummy_update (GtkLego* self, int position)
{
}

void
sensor_input_feeder_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_input_feeder->button),
                               position >= self->motor_input_feeder->end);
}

void
sensor_stage_x_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_stage_x_home->button), position <= self->motor_stage_x->home);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_stage_x_end->button), position >= self->motor_stage_x->end);
}

void
sensor_stage_y_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_stage_y_home->button), position <= self->motor_stage_y->home);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_stage_y_end->button), position >= self->motor_stage_y->end);
}

void
sensor_truck_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_truck_home->button), position <= self->motor_truck->home);
  //gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_truck_end->button), position >= self->motor_truck->end);
}

void
sensor_trolley_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_trolley_end->button), position >= self->motor_trolley->end);
}

void
sensor_hoist_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_hoist_end->button), position >= self->motor_hoist->end);
}

void
sensor_gripper_set_active (GtkLego* self, int position)
{
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->sensor_gripper_end->button), position >= self->motor_gripper->end);
}

void
gtk_lego_update (GtkLego* self)
{
  gtk_motor_update (self->motor_input_feeder, self, sensor_input_feeder_set_active);
  gtk_motor_update (self->motor_input_feedport, self, dummy_update);
  gtk_motor_update (self->motor_output_reject_track, self, dummy_update);
  gtk_motor_update (self->motor_output_accept_track, self, dummy_update);
  gtk_motor_update (self->motor_stage_x, self, sensor_stage_x_set_active);
  gtk_motor_update (self->motor_stage_y, self, sensor_stage_y_set_active);
  gtk_motor_update (self->motor_truck, self, sensor_truck_set_active);
  gtk_motor_update (self->motor_trolley, self, sensor_trolley_set_active);
  gtk_motor_update (self->motor_hoist, self, sensor_hoist_set_active);
  gtk_motor_update (self->motor_gripper, self, sensor_gripper_set_active);
}

void imotor_connect (imotor*, GtkMotor*);
void itouch_connect (itouch*, GtkSensor*);
void ilight_connect (ilight*, GtkSensor*);

typedef struct
{
  //: public itimer_impl
  struct {
    char const* name;
    void* self;
    void (*create)(itimer_impl* self,uint32_t ms);
    void (*cancel)(itimer_impl* self);
    
  } in;
  
  struct {
    char const* name;
    void* self;
    void (*timeout) (itimer_impl* self);
    
  } out;

  guint connection;
  itimer* port;
  GtkLego* lego;
} timer_impl;

void
timer_impl_init (timer_impl* self, locator* loc)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);

  self->in.name = "timer.in";
  self->in.self = 0;
  self->out.name = "itimer.out";
  self->out.self = 0;

  //self->connection = 0xdeadbeef;
  self->connection = 12345;
  self->port = locator_get (loc, "timer.port");
  self->lego = locator_get (loc, "lego");
}

bool
timer_impl_stupid_member (timer_impl* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  //fprintf (stderr, "%p: %d\n", self, self->connection);
  gtk_lego_update (self->lego);
  self->port->out.timeout (self->port);
  return false;
}

void
timer_impl_create (itimer_impl* self, int ms)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl* t = (timer_impl*)self;
  t->connection = g_timeout_add (ms, (GSourceFunc)timer_impl_stupid_member, (gpointer)self);
  //fprintf (stderr, "%p: %d\n", t, t->connection);
}

void
timer_impl_cancel (itimer_impl* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl* t = (timer_impl*)self;
  //fprintf (stderr, "%p: %d\n", t, t->connection);
  g_source_remove (t->connection);
}

timer_impl*
create_timer_impl (locator* loc)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl *t = (timer_impl*)malloc (sizeof (timer_impl));
  timer_impl_init (t, loc);
  return t;
}

void
legoballsorter_calibrated ()
{
  fputs ("LegoBallSorter.calibrated\n", stderr);
}

void
legoballsorter_finished ()
{
  fputs ("LegoBallSorter.finished\n", stderr);
}

void
calibrate_clicked (GtkWidget* w, LegoBallSorter* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  self->ctrl->in.calibrate (self->ctrl);
}

void
operate_clicked (GtkWidget* w, LegoBallSorter* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  self->ctrl->in.operate (self->ctrl);
}

void
stop_clicked (GtkWidget* w, LegoBallSorter* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  self->ctrl->in.stop (self->ctrl);
}

int
main (int argc, char** argv)
{
  gtk_init (&argc, &argv);

  runtime dezyne_runtime;
  runtime_init (&dezyne_runtime);

  locator dezyne_locator;
  locator_init (&dezyne_locator, &dezyne_runtime);

  GtkLego* lego = gtk_lego_new ();

  LegoBallSorter sut;
  dzn_meta_t m = {"sut", 0};
  locator_set (&dezyne_locator, "lego", lego);
  locator_set (&dezyne_locator, "timer.create", create_timer_impl);

  LegoBallSorter_init (&sut, &dezyne_locator, &m);

  sut.ctrl->out.name = "ctrl";
  sut.ctrl->out.self = &sut;

  g_signal_connect (lego->window, "delete-event", G_CALLBACK (gtk_main_quit), 0);
  g_signal_connect (lego->window, "destroy", G_CALLBACK (gtk_main_quit), 0);

  gtk_widget_show_all (GTK_WIDGET (lego->window));

  g_signal_connect (lego->button_calibrate, "clicked", G_CALLBACK (calibrate_clicked), &sut);
  g_signal_connect (lego->button_operate, "clicked", G_CALLBACK (operate_clicked), &sut);
  g_signal_connect (lego->button_stop, "clicked", G_CALLBACK (stop_clicked), &sut);

  sut.ctrl->out.calibrated = legoballsorter_calibrated;
  sut.ctrl->out.finished = legoballsorter_finished;

  imotor_connect (sut.brick1_aA, lego->motor_trolley);
  imotor_connect (sut.brick1_aB, lego->motor_input_feedport);
  imotor_connect (sut.brick1_aC, lego->motor_input_feeder);

  itouch_connect (sut.brick1_s1, lego->sensor_stage_x_end);
  itouch_connect (sut.brick1_s2, lego->sensor_input_feedport);
  itouch_connect (sut.brick1_s3, lego->sensor_truck_home);
  itouch_connect (sut.brick1_s4, lego->sensor_input_feeder);

  imotor_connect (sut.brick2_aA, lego->motor_output_reject_track);
  imotor_connect (sut.brick2_aB, lego->motor_output_accept_track);

  //connect (sut.brick2_s1, lego->sensor_truck_end);
  itouch_connect (sut.brick2_s2, lego->sensor_stage_x_home);
  itouch_connect (sut.brick2_s3, lego->sensor_output_reject);
  itouch_connect (sut.brick2_s4, lego->sensor_output_accept);

  imotor_connect (sut.brick3_aA, lego->motor_stage_x);
  imotor_connect (sut.brick3_aC, lego->motor_stage_y);

  ilight_connect (sut.brick3_s1, lego->sensor_light);
  itouch_connect (sut.brick3_s2, lego->sensor_stage_y_end);
  itouch_connect (sut.brick3_s3, lego->sensor_stage_y_home);

  imotor_connect (sut.brick4_aA, lego->motor_hoist);
  imotor_connect (sut.brick4_aB, lego->motor_gripper);
  imotor_connect (sut.brick4_aC, lego->motor_truck);

  itouch_connect (sut.brick4_s1, lego->sensor_gripper_end);
  itouch_connect (sut.brick4_s2, lego->sensor_trolley_end);
  itouch_connect (sut.brick4_s3, lego->sensor_hoist_end);

  gtk_main ();
  return 0;
}

//#define SHORT_CIRCUIT 1

void
imotor_in_move (imotor* self, uint8_t power, int32_t position)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  runtime_trace_in (self->in.self, self->out.self, "move");
  GtkMotor *g = self->in.self;
  g->target = position;
  runtime_trace_out (self->in.self, self->out.self, "return");
#endif
}

void
imotor_in_run (imotor* self, uint8_t power, bool invert)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  GtkMotor *g = self->in.self;
  g->target = invert ? GTK_MOTOR_MIN : GTK_MOTOR_MAX;
#endif
}

void
imotor_in_stop (imotor* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  GtkMotor *g = self->in.self;
  g->target = gtk_motor_get_value (g);
}

void
imotor_in_coast (imotor* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  GtkMotor *g = self->in.self;
  g->target = gtk_motor_get_value (g);
}

void
imotor_in_zero (imotor* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  GtkMotor *g = self->in.self;
  int current = gtk_motor_get_value (g);
  g->home -= current;
  g->end -= current;
  g->target = 0;
  gtk_motor_set_value (g, 0);
}

void
imotor_in_position (imotor* self, int32_t* position)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  GtkMotor *g = self->in.self;
  *position = gtk_motor_get_value (g);
#else
  *position = 0;
#endif
}

int
imotor_in_at (imotor* self, int32_t position)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  GtkMotor *g = self->in.self;
  return abs (position - gtk_motor_get_value (g)) <= 2
    ? imotor_result_t_yes : imotor_result_t_no;
#else
  return 0;
#endif
}

void
imotor_connect (imotor* m, GtkMotor* g)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);

  m->in.name = "imotor";
  m->in.self = g;

  m->in.move = imotor_in_move;
  m->in.run = imotor_in_run;
  m->in.stop = imotor_in_stop;
  m->in.coast = imotor_in_coast;
  m->in.zero = imotor_in_zero;
  m->in.position = imotor_in_position;
  m->in.at = imotor_in_at;
}

int
itouch_in_detect (itouch* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  GtkSensor *t = (GtkSensor*)self->in.self;
  runtime_trace_in (self->in.self, self->out.self, "detect");
  int r = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (t->button))
    ? itouch_status_pressed
    : itouch_status_released;
  runtime_trace_out (self->in.self, self->out.self, r == itouch_status_pressed ? "status_pressed" : "status_released");
  return r;
#else
  return 0;
#endif
}

void
itouch_connect (itouch* t, GtkSensor* s)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);

  t->in.name = "itouch";
  t->in.self = s;
  t->in.detect = itouch_in_detect;
}

void
ilight_in_turnon (ilight* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  GtkSensor* s = (GtkSensor*)self->in.self;
  gtk_widget_set_sensitive (GTK_WIDGET (s->button), true);
}

void
ilight_in_turnoff (ilight* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  GtkSensor* s = (GtkSensor*)self->in.self;
  gtk_widget_set_sensitive (GTK_WIDGET (s->button), false);
}

int
ilight_in_detect (ilight* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
#if !SHORT_CIRCUIT
  GtkSensor* s = (GtkSensor*)self->in.self;
  return gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (s->button))
    ? ilight_status_accept : ilight_status_reject;
#else
  return 0;
#endif
}

void
ilight_connect (ilight* l, GtkSensor* s)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);

  l->in.name = "ilight";
  l->in.self = s;

  l->in.turnon = ilight_in_turnon;
  l->in.turnoff = ilight_in_turnoff;
  l->in.detect = ilight_in_detect;
}
