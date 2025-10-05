// can_sender.hpp
#ifndef CAN_SENDER_HPP
#define CAN_SENDER_HPP

#include <string>

// Declare a function that can be called from main() or other files
int create_can_socket();

// Declare a function to send random CAN messages
void send_random_can_messages(int socket_fd);

#endif

/*
We can also define #pragma macro_name instead of ifndef
EG:
    #pragma macro_name
    ...
    ...
*/
