from Gnumeric import *
import string
from datetime import datetime
from datetime import date
from datetime import timedelta

# apt install gnumeric-plugins-extra
# cp -a shellscripts/py-cal ~/.gnumeric/<gnumeric version>/plugins

#gnumeric Tools->Plug-ins
#  Enable 'Python functions, Python plugin loader' and save.
#
#  import Gnumeric
#  dir()
#  wb=Gnumeric.workbooks()[0]
#  s=wb.sheets()[0]
#  c=s[0,0]
#  c.set_text('foo')

#see: /usr/lib/gnumeric/1.12.44/plugins/py-func

def func_build_school_term_cal():
	'@GNM_FUNC_HELP_NAME@func_build_school_term_cal:Build a calendar from \
cell 0,0 start date and cell 0,1 end date. Insert the function \
call in a cell.'

	print 'start func_build_school_term_cal()'

	CONST_gnumeric_date_1=datetime \
		.strptime('1970-01-01','%Y-%m-%d' ).date().toordinal();

	CONST_WEEK_COL= 1
	CONST_MONTH_COL= CONST_WEEK_COL
	CONST_DAY_ROW= 2
	CONST_CAL_ROW= CONST_DAY_ROW + 2
	CONST_DAY_COL= 2
	CONST_COL_SPACE= 2
	CONST_ROW_SPACE= 6

	wb = workbooks()[0]
	s = wb.sheets()[0]
	s[CONST_DAY_COL+CONST_COL_SPACE*0,CONST_DAY_ROW].set_text('Monday')
	s[CONST_DAY_COL+CONST_COL_SPACE*1,CONST_DAY_ROW].set_text('Tuesday')
	s[CONST_DAY_COL+CONST_COL_SPACE*2,CONST_DAY_ROW].set_text('Wednesday')
	s[CONST_DAY_COL+CONST_COL_SPACE*3,CONST_DAY_ROW].set_text('Thursday')
	s[CONST_DAY_COL+CONST_COL_SPACE*4,CONST_DAY_ROW].set_text('Friday')

	#Get start/end dates for the calendar.
	datetounix = functions['date2unix']
	startDate = datetounix(s[0,0].get_value())
	startDate = date.fromtimestamp(startDate)
	endDate = datetounix(s[0,1].get_value())
	endDate = date.fromtimestamp(endDate)

	currentDay = startDate
	oneDay = timedelta(1)
	lastMonth = 0

	weekCount = 0
	while currentDay < endDate:
		while currentDay.weekday() > 4:
			currentDay = currentDay + oneDay
		weekCount = weekCount + 1
		currentRow = CONST_CAL_ROW + CONST_ROW_SPACE * (weekCount - 1)
		#Print the month
		currentMonth = currentDay.month
		if currentMonth != lastMonth:
			lastMonth = currentMonth
			monthStr = currentDay.strftime('%B');
			s[CONST_MONTH_COL, currentRow+1].set_text(monthStr)
		#Print the week number
		weekStr = 'wk' + str(weekCount)
		s[CONST_WEEK_COL, currentRow].set_text(weekStr)
		while currentDay.weekday() <= 4:
			day = currentDay.weekday()
			dayStr = currentDay.strftime('%d')
			s[CONST_DAY_COL+CONST_COL_SPACE*day, currentRow].set_text(dayStr)
			currentDay = currentDay + oneDay

#	s[0,3].set_text(currentDay.isoformat())


calendar_functions = {
	'py_build_school_term_cal': func_build_school_term_cal
}
# vim:tabstop=2:shiftwidth=2:noexpandtab
