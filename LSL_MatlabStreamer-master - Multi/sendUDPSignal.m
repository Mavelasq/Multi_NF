function sendUDPSignal(msg)
    mrHandy = '192.168.2.100';
    mrHandyHome =  '192.168.178.30';
    mrLappi = '192.168.2.106';
    ipAddressMrHandy = mrHandy;
    listeningPort = 7488;
    sendingPort = 7488;
    %u = udp(ipAddressMrHandy , listeningPort, 'LocalPort', sendingPort );
    u = udp('127.0.0.1', listeningPort, 'LocalPort', sendingPort);
    fopen(u);
    fwrite(u, msg);
    fclose(u);
end
