cron = require("cron"); b,err = cron.parse_line("@directive /test/ >6 : s"); print(b,err); s,comm = b({"test",7}); print(s,comm)
-- Testing basic functionality
b,err = cron.parse_line("@directive /test/ >6 : s"); print(b,err); print(b({"test",5}));
b,err = cron.parse_line("@directive \"test\" >6 : s"); print(b,err); print(b({"nottest",7}));
b,err = cron.parse_line("*/2 14 */2 * * test"); print(b,err); print(b(os.date("*t")));
b,err = cron.parse_line("08.05.22 15:30 test"); print(b,err); print(b(os.date("*t")));
b,err = cron.parse_line("12:00 08.05.22 test"); print(b,err); print(b(os.date("*t")));
-- Testing command forming
b,err = cron.parse_line("08.05.22 15:30 test 2 the mega test"); print(b,err); print(b(os.date("*t")));
b,err = cron.parse_line("12:00 08.05.22 test supreme"); print(b,err); print(b(os.date("*t")));
b,err = cron.parse_line("*/2 14 */2 * * test of course   yet another"); print(b,err); print(b(os.date("*t")));
-- Testing parsing limits
b,err = cron.parse_line("* * * test"); print(b,err);
b,err = cron.parse_line("* * * * * * test"); print(b,err); --actually valid - and should be!
b,err = cron.parse_line("@directive /test/ >6 no delimiter error"); print(b,err);
b,err = cron.parse_line("08.05.22 shit"); print(b,err);
b,err = cron.parse_line("10:20 shit"); print(b,err);
-- Testing parsing dates and time
b,err = cron.parse_line("51.02.2022 shit"); print(b,err);
b,err = cron.parse_line("25:69 shit"); print(b,err);

