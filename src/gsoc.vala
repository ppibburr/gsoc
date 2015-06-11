namespace GSoc {
	public string? _read_io(IOChannel io) {
	  string buff = "";
	  size_t len;
	  
	  io.seek_position(0,SeekType.SET);
	  io.read_to_end(out buff, out len);

	  return buff.strip();
	}
	
	public void _write_io(IOChannel io, string what) {
		io.write_chars((char[])what, null);
		io.flush();
	}	
}
