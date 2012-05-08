/****
 *' $Header:   P:/misc/swttools/loadmap.h_v   1.2   03 Jan 1992 13:14:50   HENRY  $
 *
 * loadmap.h
 *
 * constants for loadmap.c
 *
 ****/

// state machine constants
#define ST_UNDEF	0
#define ST_SEG		1
#define ST_GROUP	2
#define ST_PUBNAME	3
#define ST_PUBVAL	4
#define ST_LINE 	5
#define ST_ENTRY	6

// tokens used to define the SEGMENT section
#define SEGT1_Start	"start"
#define SEGT3_Length	"length"
#define SEGT4_Name	"name"
#define SEGT5_Class	"class"

// GROUP section
#define GROUPT1_Origin	"origin"
#define GROUPT2_Group	"group"

// PUBNAME section
#define PUBNAMET1_Address	"address"
#define PUBNAMET2_Publics	"publics"
#define PUBNAMET3_by		"by"
#define PUBNAMET4_Name		"name"

// PUBVAL section
#define PUBVALT1_Address	PUBNAMET1_Address
#define PUBVALT2_Publics	PUBNAMET2_Publics
#define PUBVALT3_by		PUBNAMET3_by
#define PUBVALT4_Value		"value"

// LINE section
#define LINET1_Line	"line"
#define LINET2_numbers	"numbers"
#define LINET3_for	"for"

// ENTRY section
#define ENTRYT1_Program "program"
#define ENTRYT2_entry	"entry"
#define ENTRYT3_point	"point"
#define ENTRYT4_at	"at"

