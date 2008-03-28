/**
 * C99
 *
 * File extension : .fc
 */

#include <stdint.h>
#include <stdio.h>

/** Reference counting ? **/
struct fc_obj_t {
    uint32_t length;
    void *value;
}

struct fc_interp_t {
    fc_obj_t stack;
    fc_obj_t words;
};

// Global interp structure
static fc_interp_t *g_interp;

// Define default interp env
int fc_interp_setup() {
    void * moo = alloc(struct interp_t);
    // Define default words here
    return moo;
}

/**
 * Finds word in table and execute it
 */
void fc_process_word() {

}

void fc_interp_eval(FILE *stream) {
    char* next_word;

    while(int chr = fgetc(stdin)) {
        switch(chr) {
            case 20:
                if (in_word) {
                    process_word();
                    in_word = false;
                } else {
                    // ignore
                }
                break;
            case 13: // \r
            case 10: // \n
                if (in_word)
                    ...
                break;
            else:

                break;
        }
    }
}

int main(int argc, char **argv) {
    // global interpreter
    g_interp = fc_interp_setup();

    fc_interp_eval(stdin);

    return 0;
}
