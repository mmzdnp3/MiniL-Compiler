/*
*	CS 152
*	Project Phase 2
*	Ikk Anmol Singh Hundal  <861134450>
*	Chwan-Hao Tung 			<861052182>
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
	void yyerror(const char *msg);
	int yylex();
	extern int line;
	extern int pos;
	extern FILE * yyin;
%}


%union{
	int number;
	char* string;
}


%error-verbose
%start input
%token PROGRAM
%token BEGIN_PROGRAM
%token END_PROGRAM
%token INTEGER
%token ARRAY
%token OF
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token READ
%token WRITE
%token AND
%token OR
%token NOT
%token TRUE
%token FALSE
%token SUB
%token ADD
%token MULT
%token DIV
%token MOD
%token EQ
%token NEQ
%token LT
%token GT
%token LTE
%token GTE
%token SEMICOLON
%token COLON
%token COMMA
%token L_PAREN
%token R_PAREN
%token ASSIGN
%token <number> NUMBER
%token <string> IDENT
%token <string> UNRECOGNIZED
%right ASSIGN
%right COLON
%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left SUB ADD
%left MULT DIV MOD
%left L_PAREN R_PAREN


%%
			
	input:
		    program   identifier   semicolon   block   end_program		{printf("input -> program identifier semicolon block end_program\n");}
			;
			
	block:     
			declarations   begin_program   statements	{printf("block -> declarations   begin_program   statements\n");}
			;
				
	declarations: 
			  declaration   semicolon declarations		{printf("declarations -> declaration semicolon declarations\n");}
			| declaration   semicolon						{printf("declarations -> declaration semicolon\n");}
			;
			
	declaration:          
			indentifiers   colon   optional_array   integer	{printf("declaration -> indentifiers colon optional_array integer\n");}
			;
	
	indentifiers:
			identifier	comma	indentifiers		{printf("indentifiers -> identifier comma identifiers\n");}
			| identifier							{printf("indentifiers -> identifier\n");}
			;
			
	optional_array:
			array   l_paren   number   r_paren   of	{printf("optional_array -> array l_paren number r_paren of\n");}
			| /* epsilon */							{printf("optional_array -> epsilon\n");}
			;
			
	statement:
			var   assign   expression											{printf("statement -> var assign expression\n");}
			| if   bool_exp   then   statements		optional_else   end_if 	{printf("statement -> if bool_exp then statements optional_else end_if\n");}
			| while   bool_exp   begin_loop   statements   end_loop 		{printf("statement -> while bool_exp begin_loop statements end_loop\n");}
			| do   begin_loop   statements   end_loop   while bool_exp 		{printf("statement -> do begin_loop statements end_loop while bool_exp\n");}
			| read   vars 													{printf("statement -> read vars\n");}
			| write   vars 													{printf("statement -> write vars\n");}
			| continue 															{printf("statement -> continue\n");}
			;
			
	optional_else:
			else   statements		{printf("optional_else -> else statements\n");}
			| /* epsilon */				{printf("optional_else -> epsilon\n");}
			;
		
	vars:
			var		comma	vars 	{printf("vars -> var comma vars\n");}
			| var 						{printf( "vars -> var\n");}
			;
		
	statements:
			statement   semicolon	statements		{printf("statements -> statement semicolon statements\n");}
			| statement   semicolon 					{printf("statements -> statement semicolon\n");}
			;
	
	bool_exp:
			relation_and_exp	relation_and_exps 	{printf("bool_exp -> relation_and_exp relation_and_exps\n");}
			;
			
	relation_and_exps:     
			or	relation_and_exp	relation_and_exps 	{printf("relation_and_exps -> or relation_and_exp relation_and_exps\n");}
			| /* epsilon */ 								{printf("relation_and_exps -> epsilon\n");}
			;
			
	relation_and_exp:
			relation_exp   relation_exps 	{printf("relation_and_exp -> relation_exp relation_exps\n");}
			;
			
	relation_exps:
			and relation_exp relation_exps	{printf("relation_exps -> and relation_exp relation_exps\n");}
			| /* epsilon */ 					{printf("relation_exps -> epsilon\n");}
			;
	
	relation_exp:
			expression	comp	expression 			{printf("relation_exp -> expression comp expression\n");}
			| true									{printf("relation_exp -> true\n");}
			| false 								{printf("relation_exp -> false\n");}
			| l_paren	bool_exp	r_paren 		{printf("relation_exp -> l_paren bool_exp r_paren\n");}
			| not expression	comp	expression	{printf("relation_exp -> not expression comp expression\n");}
			| not true 								{printf("relation_exp -> not true\n");}
			| not false 							{printf("relation_exp -> not false\n"); }
			| not l_paren   bool_exp   r_paren 		{printf("relation_exp -> not l_paren bool_exp r_paren\n");}
			;
			
	comp:
			equal_to 					{printf("comp -> equal_to\n");}
			| not_equal_to 				{printf("comp -> not_equal_to\n");}
			| less_than 				{printf("comp -> less_than\n");}
			| greater_than 				{printf("comp -> greater_than\n");}
			| less_than_or_equal_to 	{printf("comp -> less_than_or_equal_to\n");}
			| greater_than_or_equal_to	{printf("comp -> greater_than_or_equal_to\n");}
			;
	
	expression:
			multiplicative_exp	multiplicative_exps	{printf("expression -> multiplicative_exp multiplicative_exps\n");}
			;
	
	multiplicative_exps:
			add   multiplicative_exp  multiplicative_exps		{printf("multiplicative_exps -> add multiplicative_exp multiplicative_exps\n");}
			| sub multiplicative_exp multiplicative_exps  		{printf("multiplicative_exps -> sub multiplicative_exp multiplicative_exps\n");}
			| /* epsilon */ 										{printf("multiplicative_exps -> epsilon\n");}
			;
			
	multiplicative_exp:
			term   terms	{printf("multiplicative_exp -> term terms\n");}
			;
	
	terms:
			multiply   term  terms		{printf("terms -> multiply term terms\n");}
			| divide   term  terms 		{printf("terms -> divide term terms \n");}
			| mod   term  terms			{printf("terms -> mod term terms\n");}
			| /* epsilon */ 				{printf("terms -> epsilon\n");}
			;
			
	term:
			var										{printf("term -> var\n");}
			| number								{printf("term -> number\n");}
			| l_paren   expression r_paren			{printf("term -> l_paren expression r_paren\n");}
			| sub var 	                			{printf("term -> sub var\n");}
			| sub   number              			{printf("term -> sub number\n");}
			| sub   l_paren   expression r_paren	{printf("term -> sub l_paren expression r_paren\n");}
			;
			
	var:
			identifier 										{printf("var -> identifier\n");}
			| identifier   l_paren   expression   r_paren	{printf("var -> identifier l_paren expression r_paren\n");}
			;
			
	program:                
			PROGRAM		{printf("program -> PROGRAM\n");}
			;
			
	identifier:
			IDENT		{printf("identifier -> IDENT (%s)\n", $1);}
			;
			
	semicolon:
			SEMICOLON	{printf("semicolon -> SEMICOLON\n");}
			;
			
	end_program:       
			END_PROGRAM		{printf("end_program -> END_PROGRAM\n");}
			;
			
	begin_program:
			BEGIN_PROGRAM	{printf("begin_program -> BEGIN_PROGRAM\n");}
			;
			
	comma:  
			COMMA			{printf("comma -> COMMA\n");}
			;
			
	colon:     
			COLON			{printf("colon -> COLON\n");}
			;
			
	array:
			ARRAY			{printf( "array -> ARRAY\n");}
			;
			
	number: 
			NUMBER			{printf("number -> NUMBER (%d)\n", $1);}
			;
			
	l_paren:		
			L_PAREN 		{printf("l_paren -> L_PAREN\n");}
			;
			
	r_paren:		
			R_PAREN			{printf("r_paren -> R_PAREN\n");}
			;
			
	of:           
			OF				{printf("of -> OF\n");}
			;
			
	integer:  
			INTEGER			{printf("integer -> INTEGER\n");}
			;
			
	assign:   
			ASSIGN			{printf("assign -> ASSIGN\n");}
			;
			
	if:
			IF				{printf("if -> IF\n");}
			;
			
	then:
			THEN			{printf("then -> THEN\n");}
			;
			
	end_if:
			ENDIF			{printf("endif -> ENDIF\n");}
			;
			
	else:
			ELSE			{printf("else -> ELSE\n");}
			;
			
	while:
			WHILE			{printf("while -> WHILE\n");}
			;
			
	begin_loop:
			BEGINLOOP		{printf( "begin_loop -> BEGINLOOP\n");}
			;
			
	end_loop:
			ENDLOOP			{printf("end_loop -> ENDLOOP\n");}
			;
			
	do:
			DO				{printf("do -> DO\n");}
			;
			
	read:       
			READ			{printf("read -> READ\n");}
			;
			
	write:
			WRITE			{printf("write -> WRITE\n");}
			;
			
	continue:
			CONTINUE		{printf("continue -> CONTINUE\n");}
			;
			
	or:
			OR				{printf("or -> OR\n");}
			;
			
	and: 
			AND				{printf( "and -> AND\n");}
			;
			
	not:
			NOT 			{printf("not -> NOT\n");}
			;
			
	true:
			TRUE			{printf("true -> TRUE\n");}
			;
			
	false:
			FALSE 			{printf("false -> FALSE\n");}
			;
			
	equal_to:
			EQ 				{printf("equal_to -> EQ\n");}
			;
			
	not_equal_to:
			NEQ 			{printf("not_equal_to -> NEQ\n");}
			;
			
	less_than:
			LT 				{printf("less_than -> LT\n");}
			;
			
	greater_than:
			GT				{printf("greater_than -> GT\n");}
			;
			
	less_than_or_equal_to:
			LTE				{printf("less_than_or_equal_to -> LTE\n");}
			;
			
	greater_than_or_equal_to:
			GTE 			{printf("greater_than_or_equal_to -> GTE\n");}
			;
				
	add:
			ADD 			{printf("add -> ADD\n");}
			;
			
	sub:
			SUB 			{printf("sub -> SUB\n"); }
			;
			
	multiply:
			MULT			{printf("multiply -> MULT\n");}
			;
			
	divide:
			DIV				{printf("divide -> DIVIDE\n");}
			;
			
	mod:
			MOD				{printf("mod -> MOD\n");}
            ;
            
%%


int main(int argc, char **argv)
{
   yyparse();
   return 0;
}


void yyerror(const char *msg)
{
   printf("Line %d %s\n", line, msg);
}
