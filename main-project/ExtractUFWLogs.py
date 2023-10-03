import datetime
import systemd.journal


if __name__ == '__main__':
    log_size = datetime.datetime.now() - datetime.timedelta(hours=168)
    print(log_size)
    reader = systemd.journal.Reader()
    reader.seek_realtime(log_size.timestamp())
    reader.log_level(systemd.journal.LOG_INFO)
    #reader.add_match("/")
    
    with open('Events.csv', 'a') as f:
        for entry in reader:
            f.write(
                '{}, {}, {}\n'.format(
                    entry['__REALTIME_TIMESTAMP'].strftime('%B %d %H:%M:%S'),
                    entry['_HOSTNAME'],
                    entry['MESSAGE'],
                )
        )
