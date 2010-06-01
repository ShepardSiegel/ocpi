package Alias;

typeclass Alias#(type a, type b)
   dependencies (a determines b,
		 b determines a);
endtypeclass

instance Alias#(a,a);
endinstance

typeclass NumAlias#(numeric type a, numeric type b)
   dependencies (a determines b,
		 b determines a);
endtypeclass

instance NumAlias#(a,a);
endinstance

endpackage
