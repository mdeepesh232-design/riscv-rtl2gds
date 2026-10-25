module branch_unit (
    input        branch,
    input        zero,
    output       branch_taken
);
    assign branch_taken = branch & zero;
endmodule