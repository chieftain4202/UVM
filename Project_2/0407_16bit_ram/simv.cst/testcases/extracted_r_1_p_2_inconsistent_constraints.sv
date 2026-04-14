class c_1_2;
    int cycles = 0;

    constraint c_cycles_this    // (constraint_mode = ON) (./tb_ram.sv:24)
    {
       (cycles inside {[1:20]});
    }
endclass

program p_1_2;
    c_1_2 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "zzx001z00zz1x0zx0111xx101xz01zx1zxzxxzzxxxzxzzxzzzxxxzzxzxzzxzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
