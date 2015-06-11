
namespace GSoc {
	public class GPIO : Object {
		public enum Direction {
			IN,
			OUT;
			
		  public string get_name() {
			  return this.to_string().down().split("_")[2];
		  }
			
		  public static Direction? type_from_name(string name) {
			 switch (name) {
				 case "out":
				 {
				   return OUT; 
				 }
				 case "in":
				 {
				   return IN;
				 }
			 }
			 
			 return null;
		  }		
			
		}
		
		public enum Interrupt {
			NONE,
			RISING,
			FALLING,
			BOTH;
			
		  public string get_name() {
			  return this.to_string().down().split("_")[2];
		  }
			
		  public static Interrupt? type_from_name(string? name) {
			 switch (name) {
				 case "none":
				 {
				   return NONE; 
				 }
				 case "rising":
				 {
				   return RISING;
				 }
				 case "falling":
				 {
				   return FALLING;
				 }	 
				 case "both":
				 {
				   return BOTH;
				 }
			 }
			 
			 return NONE;
		  }
		}
		
		public int pin {get;construct set;}
		public IOChannel? io_value;
		public IOChannel? io_direction;
		public IOChannel? io_edge;		
		
		public GPIO(int pin) {
			Object(pin:pin);
		}
		
		construct {
			io_value     = new IOChannel.file(@"/sys/class/gpio/gpio$(pin)/value", "r+");
			io_edge      = new IOChannel.file(@"/sys/class/gpio/gpio$(pin)/edge", "r+" );		
			io_direction = new IOChannel.file(@"/sys/class/gpio/gpio$(pin)/direction", "r+");
		}
		
		
		private Direction _get_direction() {
			return Direction.type_from_name(_read_io(io_direction));
		}
		
		private void _set_direction(Direction dir) {
			_write_io(io_direction, dir.get_name());
		}
		
		public Direction direction {
		  get {
			  return _get_direction();
		  }	
		  set {
			  _set_direction(value);
		  }
		} 
		
		private Interrupt _get_interrupt() {
			var name = _read_io(io_edge);

			return Interrupt.type_from_name(name);
		}
		
		private void _set_interrupt(Interrupt type) {
			  _write_io(io_edge, type.get_name());

			  if (type == Interrupt.NONE) {
				  _remove_listen_interrupt();
			  } else {
				  _listen_interrupt();
			  }
		
		}
		
		private bool _get_state() {
		  string buff = _read_io(io_value);

		  return buff == "1";
		}
		
		private void _set_state(bool state) {
		  if (state) {
			_write_io(io_value, "1");
		  } else {
			_write_io(io_value, "0");
		  }
		}
		
		public bool state {
			get {
				return this._get_state();
			}
			
			set {
				this._set_state(value);
			}
		}
		
		private void _listen_interrupt() {
			this._interrupt_event_source = io_value.add_watch(IOCondition.PRI, () => {
				if (this.interrupt != Interrupt.NONE) {
					on_interrupt();		
					return true;
				}
				
				return false;
			});
		}
		
		private void _remove_listen_interrupt() {
			
		}
		
		private uint _interrupt_event_source;
		
		public Interrupt interrupt {
			set {
			  this._set_interrupt(value);		
			}
			
			get {
			  return this._get_interrupt();
			}
		}
		
		public signal void on_interrupt();
	}
}
