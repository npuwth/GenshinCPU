interface cpu_dbus_if();
	// signal for I$
	logic invalidate_icache;
	// signals for D$
	logic read, write, stall, invalidate;
	// only used for write
	// byteenable[i] corresponds to wrdata[(i + 1) * 8 - 1 : i * 8]
	logic [3:0] byteenable;
	phys_t address;      // aligned in 4-bytes
	uint32_t rddata, wrdata;

	logic [`DBUS_TRANS_WIDTH-1:0] trans_in, trans_out;

	modport master (
		output read, write,
		output invalidate, invalidate_icache,
		output wrdata, address, byteenable,
		input  stall,
		input  rddata,

		output trans_in,
		input trans_out
	);

	modport slave (
		input  read, write,
		input  invalidate, invalidate_icache,
		input  wrdata, address, byteenable,
		output stall,
		output rddata,

		input trans_in,
		output trans_out
	);

endinterface