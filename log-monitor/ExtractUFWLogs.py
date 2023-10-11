import datetime
import systemd.journal


if __name__ == '__main__':
    log_size = datetime.datetime.now() - datetime.timedelta(hours=168)
    print(log_size)
    print("Extracting Logs... ")
    reader = systemd.journal.Reader()
    reader.seek_realtime(log_size.timestamp())
    reader.log_level(systemd.journal.SYSTEM_ONLY)
    #reader.add_match(_SYSTEMD_UNIT="ufw")
    
    open('Events.csv', 'w').close() # Clears file
    with open('Events.csv', 'a') as f:
        f.write("TimeCreated; Kernel; ProviderName; Message\n")
        for entry in reader:
            f.write(
                '{}; {}; UFW; {}\n'.format(
                    entry['__REALTIME_TIMESTAMP'].strftime('%y-%m-%d %H:%M:%S'),
                    entry['_HOSTNAME'],
                    entry['MESSAGE'],
                )
        )
