namespace GSoc {
	public class PWM {
		
		public int pin;
		
		public IOChannel io_enable;
		public IOChannel io_duty_cycle;	
		public IOChannel io_polarity;
		public IOChannel io_period;		
		
		private static IOChannel _io_export;
		
		static construct {
			_io_export = new IOChannel.file(@"/sys/class/pwm/export", "w+");
		}
		
		
		protected static void _export(int pin) {
		  _write_io(_io_export, "$pin");	
		}
		
		
		public PWM (int pin) {
			this.pin = pin;
			//export();
			io_enable     = new IOChannel.file(@"/sys/class/pwm/pwm$(pin)/run", "r+");
			io_duty_cycle = new IOChannel.file(@"/sys/class/pwm/pwm$(pin)/duty_ns", "r+");
			io_period     = new IOChannel.file(@"/sys/class/pwm/pwm$(pin)/period_ns", "r+");
			io_polarity   = new IOChannel.file(@"/sys/class/pwm/pwm$(pin)/polarity", "r+");		
		}
		
		
		public void export() {
			PWM._export(this.pin);
		}
		

		
		
		private bool _get_enabled() {
			return _read_io(io_enable) == "1";
		}
		
		private void _set_enabled(bool val) {
			if (val) {
			  _write_io(io_enable, "1");
			} else {
			  _write_io(io_enable, "0");
			}
		}
		
		public bool enabled {
			get {
				return _get_enabled();
			}
			
			set {
				_set_enabled(value);
			}
		}
		
		private uint _get_duty_cycle() {
			return (uint)int.parse(_read_io(io_duty_cycle));
		}
		
		private void _set_duty_cycle(uint hz) {
			_write_io(io_duty_cycle, @"$(hz)");
		}
		
		public uint duty_cycle {
			get {
				return _get_duty_cycle();
			}
			
			set {
				_set_duty_cycle(value);
			}
		}
		
		private void _set_period(uint hz) {
			_write_io(io_period, hz.to_string());
		}	
		
		private uint _get_period() {
			return (uint)int.parse(_read_io(io_period));
		}
		
		public uint period {
			get { return this._get_period(); }
			set { this._set_period(value); }
		}
		
		public class Fade : Object {
			public enum Direction {
				UP,
				DOWN;
			}
			
			private uint _step = 0;
			public uint step {
				get {
					return this._step;
				}
			}
			private int _n_ticks = 0;
			public int n_ticks {get { return this._n_ticks;}}
			public float smooth {get; construct set; default = 0.1f;}
			private uint _interval;
			public uint interval {
				get { return _interval; }
			}
			public uint length {get; construct set;}
			public Direction direction {get; construct set;}
			
			public PWM pwm {get; construct set;}
			
			public signal void finish();
			
			private uint? sid = null;
			
			
			public Fade (PWM pwm, Direction dir, uint length, uint max = -1, uint min = 0, float smooth = 0.1f) {
				if (max == -1) {
					max = pwm.period;
				}			
				Object(pwm:pwm,direction:dir,length:length, smooth:smooth, min:min, max:max);
			}		
			
			public Fade.up () {
				
			}
			
			
			construct {
				configure();
			}
			
			public void configure() {
				_interval = (uint)(length * smooth);
				_step = (max - min) / (length / interval);
			}
			
			public uint max {
				construct set; get;
			}
			
			public uint min { set; get;}
			
			public bool tick() {
				int mul = 1;
				if (direction == Direction.DOWN) {
					mul = -1;

					if (min >= pwm.duty_cycle - step) {
						pwm.duty_cycle = 0;
						finish();
						return false;
					}
				} else {
					if (max <= pwm.duty_cycle + step) {
						pwm.duty_cycle = max;
						finish();
						return false;
					}	
				}
				
				_n_ticks += 1;
		
				pwm.duty_cycle = (uint)(pwm.duty_cycle + (step * mul));
		
				return true;
			}
			
			public void stop() {
			  if (sid != null) {
				  Source.remove(sid);
			  }
			  
			  sid = null;
			}
			
			public void run() {
				Timeout.add(_interval, () => {
					if (tick()) {
						return true;
					}
					
					stop();
					
					return false;
				});
			}
		}
		
		public class Pulse : Object {
			public Fade active {get; set;}
			public Fade up {get; construct set;}
			public Fade down {get; construct set;}		
			
			public PWM pwm {get; construct set;}
			
			
			public uint max {get; construct set;}
			public uint min {get; construct set;}
			public float smooth {get; construct set;}
			public uint rate {get; construct set;}
			
			private bool _running = false;
			public bool running { get { return _running;}}
			
			public PWM.Fade.Direction stroke {
			  get {
				  return active.direction;
			  }	
			}
			
			
			public Pulse (PWM pwm, uint rate, uint max = -1, uint min = 0, float smooth = 0.008f) {
				Object(pwm:pwm, rate:rate, max:max, min:min, smooth:smooth);
			}
			
			construct {
				if (max == -1) {
					max = pwm.period;
				}
				
				up   = new Fade(pwm, PWM.Fade.Direction.UP, rate, max, min, smooth);
				down = new Fade(pwm, PWM.Fade.Direction.DOWN, rate, max, min, smooth);
			
				up.finish.connect( () => {
					active = down;
					down.run();
				});
				
				down.finish.connect( () => {
					active = up;
					up.run();
				});			
				
				notify["rate"].connect( () => {
					_adjust();
				});
			}
			
			public void stop() {
			  _running = false;
			  up.stop();
			  down.stop();
			}
			
			private void _adjust() {
				active.stop();
				
				up.length = rate;
				down.length = rate;
				up.max = max;
				down.max = max;
				up.min = min;
				down.min = min;
				up.smooth = smooth;
				down.smooth = smooth;
				
				up.configure();
				down.configure();
				
				if (running) {
				  active.run();
				}
			}
			
			public void run(Fade? start = null) {
				if (start == null) {
					start = up;
				}
				
				start.finish.connect(() => {
					cross();
				});
				
				active = start;
				active.run();
			}
			
			public signal void cross();
		}
	}
}
