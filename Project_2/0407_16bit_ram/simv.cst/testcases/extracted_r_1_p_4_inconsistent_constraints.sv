class c_1_4;
    int cycles = 0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (./tb_ram.sv:89)
    {
       (cycles inside {[1:5]});
    }
endclass

program p_1_4;
    c_1_4 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "00z0x01x01101zzx1zxx0z10100zzzz0zzzxzzxzzxzzzxzxxxxxxzzxzxzzxxzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
