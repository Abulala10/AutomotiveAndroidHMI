#include "../include/can_sender.hpp"
#include <linux/can.h>
#include <linux/can/raw.h>
#include <sys/socket.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <ctime>

using namespace std;


int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        cerr << "Usage: " << argv[0] << "<vcan_interface>\n";
        return 1;
    }
    int s = create_can_socket();
    cout << "Socket Generated.\n";
    return 0;
}

int create_can_socket()
{
    int s = socket(PF_CAN, SOCK_RAW, CAN_RAW); 
    
    if (s < 0)
    {
        perror("Socket creation failed");
        return 1;
    }

    //// Interface request   
    struct ifreq ifr;
    strncpy(ifr.ifr_name, "vcan0", IFNAMSIZ - 1); // dest, src, n(16)
    ifr.ifr_name[IFNAMSIZ - 1] = '\0'; // Ensures the str is properly null terminated.
    return s;

}