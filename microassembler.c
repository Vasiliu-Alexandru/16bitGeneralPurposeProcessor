#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h> // For uint16_t

#define INPUT_FILE  "microcode.txt"
#define OUTPUT_FILE "microcode.bin"

// --- FIELD SIZES (Total 16 bits) ---
// Layout: [15..12 CS] [11..5 BA] [4..0 CF]
#define CF_size 5  // Control Field
#define BA_size 7  // Branch Address
#define CS_size 4  // Condition Select

#define MAX_LINE 256
#define MAX_LABELS 256

// --- CONDITION CODES (CS) ---
#define NOP_CS_VALUE   0b0000 // 0 = no conditional jump
#define UNCOND_JUMP_CS 0b1111 
#define zero           0b0001
#define negative       0b0010
#define carry          0b0011
#define overflow       0b0100
#define BOOTH01        0b0101
#define BOOTH10        0b0110
#define count15        0b0111
#define DECODE         0b1000

typedef struct {
    char name[64];
    int address;
} Label;

Label labels[MAX_LABELS];
int label_count = 0;

char *trim(char *s) {
    while (isspace(*s)) s++;
    char *end = s + strlen(s) - 1;
    while (end >= s && isspace(*end)) *end-- = 0;
    return s;
}

void strip_comment(char *s) {
    char *p = strchr(s, ';');
    if (p) *p = 0;
}

int find_label(const char *name) {
    for (int i = 0; i < label_count; i++) {
        if (strcmp(labels[i].name, name) == 0)
            return labels[i].address;
    }
    return -1;
}

void add_label(const char *name, int address) {
    if (label_count >= MAX_LABELS) {
        fprintf(stderr, "Error: Max labels reached.\n");
        exit(1);
    }
    strcpy(labels[label_count].name, name);
    labels[label_count].address = address;
    label_count++;
}

void print_bits(unsigned value, int bits) {
    for (int i = bits - 1; i >= 0; i--)
        printf("%c", (value & (1u << i)) ? '1' : '0');
}

int main(void) {
    FILE *in = fopen(INPUT_FILE, "r");
    if (!in) {
        printf("Error: Could not open %s\n", INPUT_FILE);
        return 1;
    }

    FILE *out_bin = fopen(OUTPUT_FILE, "w"); // ASCII output
    if (!out_bin) {
        printf("Error: Could not create %s\n", OUTPUT_FILE);
        fclose(in);
        return 1;
    }

    char line[MAX_LINE];
    int micro_pc = 0;

    // --- PASS 1: COLLECT LABELS ---
    printf("Pass 1: Parsing labels...\n");
    while (fgets(line, sizeof(line), in)) {
        char *s = trim(line);
        strip_comment(s);
        s = trim(s);
        if (*s == 0) continue;
        if (s[0] == '"') {
            char *end = strchr(s + 1, '"');
            if (end) { *end = 0; add_label(s + 1, micro_pc); }
            continue;
        }
        micro_pc++;
    }

    rewind(in);
    micro_pc = 0;

    // --- PASS 2: GENERATE AND PRINT ---
    printf("Pass 2: Generating microcode to '%s'...\n\n", OUTPUT_FILE);
    printf("ADDR | HEX  | CS(4) BA(7) CF(5) | SOURCE CODE\n");
    printf("-----|------|-------------------|-----------------------------------\n");

    while (fgets(line, sizeof(line), in)) {
        char *original_line = strdup(line); // Keep copy for display
        original_line[strcspn(original_line, "\n")] = 0; // Remove newline
        
        char *s = trim(line);
        strip_comment(s);
        s = trim(s);
        
        if (*s == 0) { free(original_line); continue; }

        // Print Section Headers (Labels)
        if (s[0] == '"') {
            char *end = strchr(s + 1, '"');
            if (end) {
                *end = 0;
                printf("\n// --- %s (Address 0x%02X) ---\n", s + 1, micro_pc);
            }
            free(original_line);
            continue;
        }

        unsigned CS = NOP_CS_VALUE;
        unsigned BA = 0;
        unsigned CF = 0; 

        char tmp[MAX_LINE];
        strcpy(tmp, s);
        char *tok = strtok(tmp, " \t");

        while (tok) {
            if (strcmp(tok, "if") == 0) {
                tok = strtok(NULL, " \t");
                if (tok) {
                    if (strcmp(tok, "zero_flag") == 0)      CS = zero;
                    else if (strcmp(tok, "negative_flag") == 0) CS = negative;
                    else if (strcmp(tok, "carry_flag") == 0) CS = carry;
                    else if (strcmp(tok, "overflow_flag") == 0) CS = overflow;
                    else if (strcmp(tok, "DECODE") == 0)    CS = DECODE;
                    else if (strcmp(tok, "BOOTH01") == 0)    CS = BOOTH01;
                    else if (strcmp(tok, "BOOTH10") == 0)    CS = BOOTH10;
                    else if (strcmp(tok, "count15") == 0)    CS = count15;


                }
            }
            else if (strcmp(tok, "goto") == 0) {
                tok = strtok(NULL, " \t\"");
                if (tok) {
                    int addr = find_label(tok);
                    if (addr != -1) BA = addr;
                    else printf("\n[ERROR] Label not found: %s\n", tok);
                    if (CS == NOP_CS_VALUE) CS = UNCOND_JUMP_CS;
                }
            }
            else if (strcmp(tok, "activate") == 0) {
                tok = strtok(NULL, " \t");
                while(tok && (strncmp(tok, "if", 2) != 0) && (strncmp(tok, "goto", 4) != 0)) {
                    char *comma = strchr(tok, ',');
                    if(comma) *comma = 0;

                    if (strcmp(tok, "state26") == 0)      CF = 26; 
                    else if (strcmp(tok, "state27") == 0) CF = 27; 
                    else if (strcmp(tok, "state28") == 0) CF = 28; 
                    else if (strcmp(tok, "state29") == 0) CF = 29; 
                    else if (tok[0] == 'c')               CF = atoi(tok + 1) + 1; // c0 → 1
                    else if (tok[0] == 's')               CF = atoi(tok + 1) + 1; // s0 → 1
                    else                                  CF = atoi(tok);         

                    tok = strtok(NULL, " \t");
                }
                continue;
            }
            tok = strtok(NULL, " \t");
        }

        // Pack bits: CS(15-12) | BA(11-5) | CF(4-0)
        uint16_t instruction = ((CS & 0xF) << 12) | ((BA & 0x7F) << 5) | (CF & 0x1F);

        // Write ASCII binary to file
        for (int i = 15; i >= 0; i--) {
            fputc((instruction & (1u << i)) ? '1' : '0', out_bin);
        }
        fputc('\n', out_bin);

        // Display Info
        printf("0x%02X | %04X | ", micro_pc, instruction);
        print_bits(CS, CS_size); printf(" ");
        print_bits(BA, BA_size); printf(" ");
        print_bits(CF, CF_size);
        printf(" | %s\n", trim(original_line));

        free(original_line);
        micro_pc++;
    }

    fclose(in);
    fclose(out_bin);
    printf("\nSuccess! Binary output written to %s\n", OUTPUT_FILE);
    return 0;
}
