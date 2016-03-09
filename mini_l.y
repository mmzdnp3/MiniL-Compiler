/*
*	CS 152
*	Project Phase 2
*	Ikk Anmol Singh Hundal  <861134450>
*	Chwan-Hao Tung 			<861052182>
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
    #include <map>
    #include <set>
    #include <string>
    #include <vector>
    #include <stack>
    #include <iostream>
    #include <algorithm>
        
    using namespace std;

	void yyerror(const char *msg);
	int yylex();
	extern int line;
	extern int pos;
	extern FILE * yyin;

    typedef struct _minilval{
        char type;
        int size;
    } minilval;

    vector<string> program_vec;
    map<string, minilval> symbol_table;
    vector<string> declarations;

    int isArray = -1;

    /* List of defines for generateInstruction() One for each syntax */
    #define OP_VAR_DEC 0
    #define OP_ARR_VAR_DEC 1
    #define OP_COPY_STATEMENT 2
    #define OP_ARR_ACCESS_SRC 3 
    #define OP_ARR_ACCESS_DST 4
    #define OP_STD_IN 5
    #define OP_STD_IN_ARR 6
    #define OP_STD_OUT 7
    #define OP_STD_OUT_ARR 8
    #define OP_ADD 9
    #define OP_SUB 10
    #define OP_MULT 11
    #define OP_DIV 12
    #define OP_MOD 13
    #define OP_LT 14
    #define OP_LTE 15
    #define OP_NEQ 16
    #define OP_EQ 17
    #define OP_GTE 18
    #define OP_GT 19
    #define OP_OR 20
    #define OP_AND 21
    #define OP_NOT 22
    #define OP_LABEL_DEC 23
    #define OP_GOTO 24
    #define OP_IF_GOTO 25

    /*Since theres no bool in c*/
    #define OP_TRUE 26
    #define OP_FALSE 27

    /*Nodes store the MIL intermediate code syntax*/
    typedef struct _Node Node;

    struct _Node
    {
        Node* next;
        char val[256];
    };

    /*Serve as the head and tail for our program*/
    Node* programStart = NULL;
    Node* programEnd = NULL;

    /*Function prototypes*/
    void generateInstruction(Node *, int, char*, char*, char*);
    void addInstruction(int, int, char*, char*, char*);
    void writeToFile(char*);

    /* Helper functions */
    char * newPredicate();
    char * newTemp();
    char * newLabel();
    int predicate = 0;
    int temp = 0;
    int label = 0;
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
		    program   identifier   semicolon   block   end_program		
                {
                    map<string, minilval>::iterator it; 
                    for(it=symbol_table.begin(); it!=symbol_table.end();++it){
                        cout << it->first << " " << it->second.type;
                        if(it->second.type == 'A'){
                            cout <<  " " << it->second.size;
                        }  
                        cout << endl;
                    }
                    printf("input -> program identifier semicolon block end_program\n");
                }
			;
			
	block:     
			declarations   begin_program   statements	{printf("block -> declarations   begin_program   statements\n");}
			;
				
	declarations: 
			  declaration   semicolon declarations		{printf("declarations -> declaration semicolon declarations\n");}
			| declaration   semicolon						{printf("declarations -> declaration semicolon\n");}
			;
			
	declaration:          
			indentifiers   colon   optional_array   integer	
                {
                /*
                    cout << "Size is " << declarations.size() << endl; 
                    for (int i = 0; i<declarations.size(); i++)
                        cout << declarations.at(i) << endl;
                    exit(1);
                    for (int i = 0; i<declarations.size(); ++i){
                        for(int j = i+1; j<declarations.size(); ++j){
                            cout << "asdasd Outer " << declarations[i] << endl;
                            cout << "asdasd Inner " << declarations[j] << endl;
                            if(declarations[i] == declarations[j]){
                                string errstr = "Multiple Declaration of " + declarations[i];
                                yyerror(errstr.c_str());
                                exit(0);
                            }
                        }
                    }*/
                    exit(1);
                    while(!declarations.empty() && declarations.size() > 1){
                        string x = declarations.back();
                        declarations.pop_back();
                        minilval * val = new minilval;
                        if(isArray>=0) {
                            val->type = 'A';
                            val->size = isArray;
                        }
                        else {
                            val->type = 'I';
                        }
                        symbol_table.insert(pair<string, minilval>(x, *val) );
                    }
                    printf("declaration -> indentifiers colon optional_array intege\n");
                }
			;
	
	indentifiers:
			identifier	comma	indentifiers		{printf("indentifiers -> identifier comma identifiers\n");}
			| identifier							{printf("indentifiers -> identifier\n");}
			;
			
	optional_array:
			array   l_paren   NUMBER   r_paren   of	
                {
                    printf("optional_array -> array l_paren number r_paren of\n");
                    isArray = $3;
                }
			| /* epsilon */							
                {
                    isArray = -1;
                    printf("optional_array -> epsilon\n");
                }
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
			PROGRAM		{}
			;
			
	identifier:
			IDENT	{
                        declarations.push_back(string($1));
                        printf("identifier -> IDENT (%s)\n", $1);
                    }
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


/* Given the instruction and operands, fill the value of newNode with the corresponding syntax */
void generateInstruction(Node* newNode, int INSTR_VALUE, char* operand1, char* operand2, char* operand3)
{
	switch(INSTR_VALUE)
	{
		/*Ex: If the instruction is variable declaration*/
		case(OP_VAR_DEC):
		{
			/*Set newNode->val to be ". name", in which name is operand1 */
			sprintf(newNode->val, ". %s", operand1);
			break;
		}
		case(OP_ARR_VAR_DEC):
		{
			sprintf(newNode->val, ".[] %s, %s", operand1, operand2);
			break;
		}
		case(OP_COPY_STATEMENT):
		{
			sprintf(newNode->val, "= %s, %s", operand1, operand2);
			break;
		}
		case(OP_ARR_ACCESS_SRC):
		{
			sprintf(newNode->val, "=[] %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_ARR_ACCESS_DST):
		{
			sprintf(newNode->val, "[]= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_STD_IN):
		{
			sprintf(newNode->val, ".< %s", operand1);
			break;
		}
		case(OP_STD_IN_ARR):
		{
			sprintf(newNode->val, ".[]< %s, %s", operand1, operand2);
			break;
		}
		case(OP_STD_OUT):
		{
			sprintf(newNode->val, ".> %s", operand1);
			break;
		}
		case(OP_STD_OUT_ARR):
		{
			sprintf(newNode->val, ".[]> %s, %s", operand1, operand2);
			break;
		}
		case(OP_ADD):
		{
			sprintf(newNode->val, "+ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_SUB):
		{
			sprintf(newNode->val, "- %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MULT):
		{
			sprintf(newNode->val, "* %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_DIV):
		{
			sprintf(newNode->val, "/ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MOD):
		{
			sprintf(newNode->val, "%% %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LT):
		{
			sprintf(newNode->val, "< %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LTE):
		{
			sprintf(newNode->val, "<= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NEQ):
		{
			sprintf(newNode->val, "!= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_EQ):
		{
			sprintf(newNode->val, "== %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GTE):
		{
			sprintf(newNode->val, ">= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GT):
		{
			sprintf(newNode->val, "> %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_OR):
		{
			sprintf(newNode->val, "|| %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_AND):
		{
			sprintf(newNode->val, "&& %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NOT):
		{
			sprintf(newNode->val, "! %s, %s", operand1, operand2);
			break;
		}
		case(OP_LABEL_DEC):
		{
			sprintf(newNode->val, ": %s", operand1);
			break;
		}
		case(OP_GOTO):
		{
			sprintf(newNode->val, ":= %s", operand1);
			break;
		}
		case(OP_IF_GOTO):
		{
			sprintf(newNode->val, "?:= %s, %s", operand1, operand2);
			break;
		}
		default:
		{
            printf("Unknown Operation");
			exit(0);
			break;
		}
	}
}


/*	For every semantic in the .y file (from the diagrams & stuff), call addInstruction if it reduces to a correct semantic \
	EX: \
	statement:	var assign expression \
			{	1. If var is an array type (Hint: check in 'var' definition) \
					-> addInstruction(FALSE, INSTR_ASSIGN_ARRAY, var identifier...) \
*/
void addInstruction(int isFront, int INSTRUCTION, char* operator1, char* operator2, char* operator3)
{
	/*Pseudocode
		1. Create empty newNode, use (Node*)(malloc(sizeof(Node)))
		2. Call generateInstruction to populate newNode with the instruction string
		3. If programStart == NULL, then programStart = programEnd = newNode & return
		4. Else if isFront == TRUE, then newNode->next = programStart & programStart = newNode
		5. Else if isFront == FALSE, then newNode->next = NULL & programEnd->next = newNode & programEnd = newNode
		6. Return
	*/
	
	/*1 */
	Node* newNode = (Node*)(malloc(sizeof(Node)));
		
	/*2 */
	generateInstruction(newNode, INSTRUCTION, operator1, operator2, operator3);

	/*3 */
	if(programStart == NULL)
	{
		programStart = newNode;
		programEnd = newNode;
		return;
	}

	/*4 */
	else if(isFront == OP_TRUE)
	{
		newNode->next = programStart;
		programStart = newNode;
	}

	/*5 */
	else if(isFront == OP_FALSE)
	{
		newNode->next = NULL;
		programEnd->next = newNode;
		programEnd = newNode;
	}

	/*6 */
	return;		 
}


/*Make mil file based off of what its name is supposed to be and fill it with the syntax from nodes*/
void writeToFile(char* fileName)
{
	char fileNameBuffer[128];
	
	/*Name the .mil file what is stated in the file */
	sprintf(fileNameBuffer, "%s.mil", fileName);

	/*Open file to write to */
	FILE *fp = fopen(fileNameBuffer, "w");

	/*Pseudocode
		1. For each node created in addInstruction, write value to fp using fprintf(fp, "%s\n",)
		2. fclose(fp)
	*/

    Node * curr;
	
	for(curr = programStart; curr != NULL; curr = curr->next)
	{
		fprintf(fp, "%s\n", curr->val);
	}

	fclose(fp);
	
}


char * newLabel()
{
    /* Output: char * - unique variable identifier of the form L# used in conditional boolean expressions.*/
    char *ret = (char *)(malloc(8));
    sprintf(ret, "L%d", label);

    ++label;

    return ret;
}


char * newTemp()
{
    /* Output: char * - unique variable identifier of the form t# used in conditional boolean expressions.*/

    char *ret = (char *)(malloc(8));
    sprintf(ret, "t%d", temp);

    ++temp;

    return ret;
}


char* newPredicate()
{
	/* Output: char * - unique variable identifier of the form p# used in conditional boolean expressions */

	char *ret = (char *)(malloc(8));
	sprintf(ret, "p%d", predicate);
	
    ++predicate;
		
	return ret;
}
