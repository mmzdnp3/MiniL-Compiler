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

    class MiniVal{
        public:
            char type;
            int size;
            
            MiniVal(char type, int size=0)
            :type(type), size(size){}
    };
    
    vector<string> program_vec;
    map<string, MiniVal> symbol_table;
    vector<string> declarations;

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

    /*Function prototypes*/
    void checkAndInsertDeclaration(string);
    string generateInstruction( int, string, string, string);
    string addInstruction(int, string, string, string);
    void writeToFile(string);

    /* Helper functions */
    string newPredicate();
    string newTemp();
    string newLabel();
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
		    program_declaration   SEMICOLON   block   END_PROGRAM
                {
                    map<string, MiniVal>::iterator it; 
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

    program_declaration: 
            PROGRAM IDENT
                {
                    symbol_table.insert(pair<string, MiniVal>(string($2), MiniVal('P')) );
                }
            ;            
            
			
	block:     
			declarations   BEGIN_PROGRAM   statements	{printf("block -> declarations   begin_program   statements\n");}
			;
				
	declarations: 
	        declaration   SEMICOLON declarations		{printf("declarations -> declaration semicolon declarations\n");}
			| declaration   SEMICOLON						{printf("declarations -> declaration semicolon\n");}
			;
			
	declaration:          
	        indentifiers   COLON    INTEGER 
                {
                    while(!declarations.empty()){
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('I')) );
                    }
                }
			| indentifiers   COLON    ARRAY   L_PAREN   NUMBER   R_PAREN   OF  INTEGER
                {
                    while(!declarations.empty()){
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('A', $5)) );
                    }
                    printf("declaration -> indentifiers colon optional_array intege\n");
                }
			;
	
	indentifiers:
	        IDENT  COMMA	indentifiers    {checkAndInsertDeclaration(string($1));}
			| IDENT							{checkAndInsertDeclaration(string($1));}
			;
			
	statement:
			var   ASSIGN   expression											{printf("statement -> var assign expression\n");}
			| IF   bool_exp   THEN   statements   ENDIF 	{printf("statement -> if bool_exp then statements optional_else end_if\n");}
			| IF   bool_exp   THEN   statements   ELSE statements   ENDIF 	{printf("statement -> if bool_exp then statements optional_else end_if\n");}
			| WHILE   bool_exp   BEGINLOOP   statements   ENDLOOP 		{printf("statement -> while bool_exp begin_loop statements end_loop\n");}
			| DO   BEGINLOOP   statements   ENDLOOP   WHILE   bool_exp 		{printf("statement -> do begin_loop statements end_loop while bool_exp\n");}
			| READ   vars 													{printf("statement -> read vars\n");}
			| WRITE   vars 													{printf("statement -> write vars\n");}
			| CONTINUE 															{printf("statement -> continue\n");}
			;
		
	vars:
			var    COMMA    vars 	{printf("vars -> var comma vars\n");}
			| var 						{printf( "vars -> var\n");}
			;
		
	statements:
			statement   SEMICOLON	statements		{printf("statements -> statement semicolon statements\n");}
			| statement   SEMICOLON 					{printf("statements -> statement semicolon\n");}
			;
	
	bool_exp:
			relation_and_exp 	{printf("bool_exp -> relation_and_exp relation_and_exps\n");}
			| relation_and_exp	OR  bool_exp 	{printf("bool_exp -> relation_and_exp relation_and_exps\n");}
			;
			
	relation_and_exp:
			relation_exp    {printf("relation_and_exp -> relation_exp relation_exps\n");}
			| relation_exp  AND relation_and_exp 	{printf("relation_and_exp -> relation_exp relation_exps\n");}
			;
	
	relation_exp:
			expression	comp	expression 			{printf("relation_exp -> expression comp expression\n");}
			| TRUE									{printf("relation_exp -> true\n");}
			| FALSE 								{printf("relation_exp -> false\n");}
			| L_PAREN	bool_exp	R_PAREN 		{printf("relation_exp -> l_paren bool_exp r_paren\n");}
			| NOT expression	comp	expression	{printf("relation_exp -> not expression comp expression\n");}
			| NOT TRUE 								{printf("relation_exp -> not true\n");}
			| NOT FALSE 							{printf("relation_exp -> not false\n"); }
			| NOT L_PAREN   bool_exp   R_PAREN 		{printf("relation_exp -> not l_paren bool_exp r_paren\n");}
			;
			
	comp:
			EQ 					{printf("comp -> equal_to\n");}
			| NEQ 				{printf("comp -> not_equal_to\n");}
			| LT 				{printf("comp -> less_than\n");}
			| GT 				{printf("comp -> greater_than\n");}
			| LTE 	            {printf("comp -> less_than_or_equal_to\n");}
			| GTE	            {printf("comp -> greater_than_or_equal_to\n");}
			;
	
	expression:
			multiplicative_exp	                        {printf("expression -> multiplicative_exp multiplicative_exps\n");}
			| multiplicative_exp    ADD   expression	{printf("expression -> multiplicative_exp multiplicative_exps\n");}
			| multiplicative_exp    SUB   expression	{printf("expression -> multiplicative_exp multiplicative_exps\n");}
			;
			
	multiplicative_exp:
			term   {printf("multiplicative_exp -> term terms\n");}
			| term MULT  multiplicative_exp	{printf("terms -> multiply term terms\n");}
			| term DIV   multiplicative_exp  {printf("terms -> divide term terms \n");}
			| term MOD   multiplicative_exp  {printf("terms -> mod term terms\n");}
			;
			
	term:
			var										{printf("term -> var\n");}
			| NUMBER								{printf("term -> number\n");}
			| L_PAREN   expression R_PAREN			{printf("term -> l_paren expression r_paren\n");}
			| SUB   var 	                			{printf("term -> sub var\n");}
			| SUB   NUMBER              			{printf("term -> sub number\n");}
			| SUB   L_PAREN   expression R_PAREN	{printf("term -> sub l_paren expression r_paren\n");}
			;
			
	var:
			IDENT	{
                        declarations.push_back(string($1));
                        printf("identifier -> IDENT (%s)\n", $1);
                    }
			| IDENT   L_PAREN   expression   R_PAREN	{printf("var -> identifier l_paren expression r_paren\n");}
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


void checkAndInsertDeclaration(string identName){

    if( (find(declarations.begin(), declarations.end(), identName) != declarations.end())
        || (symbol_table.find(identName) != symbol_table.end() )) {
        string errstr = "Multiple Declarations with identifier " + identName;
        yyerror(errstr.c_str());
        exit(0);
    }
    declarations.push_back(identName);

}

/* Given the instruction and operands, fill the value of newNode with the corresponding syntax */

//void generateInstruction(Node* newNode, int INSTR_VALUE, char* operand1, char* operand2, char* operand3)
//{
//	switch(INSTR_VALUE)
//	{
//		/*Ex: If the instruction is variable declaration*/
//		case(OP_VAR_DEC):
//		{
//			/*Set newNode->val to be ". name", in which name is operand1 */
//			sprintf(newNode->val, ". %s", operand1);
//			break;
//		}
//		case(OP_ARR_VAR_DEC):
//		{
//			sprintf(newNode->val, ".[] %s, %s", operand1, operand2);
//			break;
//		}
//		case(OP_COPY_STATEMENT):
//		{
//			sprintf(newNode->val, "= %s, %s", operand1, operand2);
//			break;
//		}
//		case(OP_ARR_ACCESS_SRC):
//		{
//			sprintf(newNode->val, "=[] %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_ARR_ACCESS_DST):
//		{
//			sprintf(newNode->val, "[]= %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_STD_IN):
//		{
//			sprintf(newNode->val, ".< %s", operand1);
//			break;
//		}
//		case(OP_STD_IN_ARR):
//		{
//			sprintf(newNode->val, ".[]< %s, %s", operand1, operand2);
//			break;
//		}
//		case(OP_STD_OUT):
//		{
//			sprintf(newNode->val, ".> %s", operand1);
//			break;
//		}
//		case(OP_STD_OUT_ARR):
//		{
//			sprintf(newNode->val, ".[]> %s, %s", operand1, operand2);
//			break;
//		}
//		case(OP_ADD):
//		{
//			sprintf(newNode->val, "+ %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_SUB):
//		{
//			sprintf(newNode->val, "- %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_MULT):
//		{
//			sprintf(newNode->val, "* %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_DIV):
//		{
//			sprintf(newNode->val, "/ %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_MOD):
//		{
//			sprintf(newNode->val, "%% %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_LT):
//		{
//			sprintf(newNode->val, "< %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_LTE):
//		{
//			sprintf(newNode->val, "<= %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_NEQ):
//		{
//			sprintf(newNode->val, "!= %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_EQ):
//		{
//			sprintf(newNode->val, "== %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_GTE):
//		{
//			sprintf(newNode->val, ">= %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_GT):
//		{
//			sprintf(newNode->val, "> %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_OR):
//		{
//			sprintf(newNode->val, "|| %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_AND):
//		{
//			sprintf(newNode->val, "&& %s, %s, %s", operand1, operand2, operand3);
//			break;
//		}
//		case(OP_NOT):
//		{
//			sprintf(newNode->val, "! %s, %s", operand1, operand2);
//			break;
//		}
//		case(OP_LABEL_DEC):
//		{
//			sprintf(newNode->val, ": %s", operand1);
//			break;
//		}
//		case(OP_GOTO):
//		{
//			sprintf(newNode->val, ":= %s", operand1);
//			break;
//		}
//		case(OP_IF_GOTO):
//		{
//			sprintf(newNode->val, "?:= %s, %s", operand1, operand2);
//			break;
//		}
//		default:
//		{
//            printf("Unknown Operation");
//			exit(0);
//			break;
//		}
//	}
//}
//
//
///*	For every semantic in the .y file (from the diagrams & stuff), call addInstruction if it reduces to a correct semantic \
//	EX: \
//	statement:	var assign expression \
//			{	1. If var is an array type (Hint: check in 'var' definition) \
//					-> addInstruction(FALSE, INSTR_ASSIGN_ARRAY, var identifier...) \
//*/
//void addInstruction(int isFront, int INSTRUCTION, char* operator1, char* operator2, char* operator3)
//{
//	/*Pseudocode
//		1. Create empty newNode, use (Node*)(malloc(sizeof(Node)))
//		2. Call generateInstruction to populate newNode with the instruction string
//		3. If programStart == NULL, then programStart = programEnd = newNode & return
//		4. Else if isFront == TRUE, then newNode->next = programStart & programStart = newNode
//		5. Else if isFront == FALSE, then newNode->next = NULL & programEnd->next = newNode & programEnd = newNode
//		6. Return
//	*/
//	
//	/*1 */
//	Node* newNode = (Node*)(malloc(sizeof(Node)));
//		
//	/*2 */
//	generateInstruction(newNode, INSTRUCTION, operator1, operator2, operator3);
//
//	/*3 */
//	if(programStart == NULL)
//	{
//		programStart = newNode;
//		programEnd = newNode;
//		return;
//	}
//
//	/*4 */
//	else if(isFront == OP_TRUE)
//	{
//		newNode->next = programStart;
//		programStart = newNode;
//	}
//
//	/*5 */
//	else if(isFront == OP_FALSE)
//	{
//		newNode->next = NULL;
//		programEnd->next = newNode;
//		programEnd = newNode;
//	}
//
//	/*6 */
//	return;		 
//}
//
//
///*Make mil file based off of what its name is supposed to be and fill it with the syntax from nodes*/
//void writeToFile(char* fileName)
//{
//	char fileNameBuffer[128];
//	
//	/*Name the .mil file what is stated in the file */
//	sprintf(fileNameBuffer, "%s.mil", fileName);
//
//	/*Open file to write to */
//	FILE *fp = fopen(fileNameBuffer, "w");
//
//	/*Pseudocode
//		1. For each node created in addInstruction, write value to fp using fprintf(fp, "%s\n",)
//		2. fclose(fp)
//	*/
//
//    Node * curr;
//	
//	for(curr = programStart; curr != NULL; curr = curr->next)
//	{
//		fprintf(fp, "%s\n", curr->val);
//	}
//
//	fclose(fp);
//	
//}
//
//
//char * newLabel()
//{
//    /* Output: char * - unique variable identifier of the form L# used in conditional boolean expressions.*/
//    char *ret = (char *)(malloc(8));
//    sprintf(ret, "L%d", label);
//
//    ++label;
//
//    return ret;
//}
//
//
//char * newTemp()
//{
//    /* Output: char * - unique variable identifier of the form t# used in conditional boolean expressions.*/
//
//    char *ret = (char *)(malloc(8));
//    sprintf(ret, "t%d", temp);
//
//    ++temp;
//
//    return ret;
//}
//
//
//char* newPredicate()
//{
//	/* Output: char * - unique variable identifier of the form p# used in conditional boolean expressions */
//
//	char *ret = (char *)(malloc(8));
//	sprintf(ret, "p%d", predicate);
//	
//    ++predicate;
//		
//	return ret;
//}
