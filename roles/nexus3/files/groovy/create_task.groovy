import groovy.json.JsonSlurper
import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskInfo
import org.sonatype.nexus.scheduling.TaskScheduler
import org.sonatype.nexus.scheduling.schedule.Schedule
import org.sonatype.nexus.scheduling.schedule.Monthly.CalendarDay
import org.sonatype.nexus.scheduling.schedule.Weekly.Weekday

parsed_args = new JsonSlurper().parseText(args)

TaskScheduler taskScheduler = container.lookup(TaskScheduler.class.getName())

TaskInfo existingTask = taskScheduler.listsTasks().find { TaskInfo taskInfo ->
    taskInfo.name == parsed_args.name
}

if (existingTask && existingTask.getCurrentState().getRunState() != null) {
    log.info("Could not update currently running task : " + parsed_args.name)
    return
}

TaskConfiguration taskConfiguration = taskScheduler.createTaskConfigurationInstance(parsed_args.typeId)
if (existingTask) { taskConfiguration.setId(existingTask.getId()) }
taskConfiguration.setName(parsed_args.name)

parsed_args.taskProperties.each { key, value -> taskConfiguration.setString(key, value) }

if (parsed_args.task_alert_email) {
    taskConfiguration.setAlertEmail(parsed_args.task_alert_email)
}

parsed_args.booleanTaskProperties.each { key, value -> taskConfiguration.setBoolean(key, Boolean.valueOf(value)) }

Schedule schedule

if (parsed_args.cron) {
    schedule = taskScheduler.scheduleFactory.cron(new Date(), parsed_args.cron)
} else if (parsed_args.daily) {
    schedule = taskScheduler.scheduleFactory.daily(new Date())
} else if (parsed_args.hourly) {
    schedule = taskScheduler.scheduleFactory.hourly(new Date())
} else if (parsed_args.monthly) {
    Set<CalendarDay> days
    parsed_args.monthly.each { value -> days.add(CalendarDay.day(Integer.valueOf(value))) }
    schedule = taskScheduler.scheduleFactory.monthly(new Date(), parsed_args.monthly)
} else if (parsed_args.once) {
    schedule = taskScheduler.scheduleFactory.once(new Date())
} else if (parsed_args.weekly) {
    Set<Weekday> days
    parsed_args.weekly.each { value -> days.add(Weekday.valueOf(value)) }
    schedule = taskScheduler.scheduleFactory.weekly(new Date(), parsed_args.weekly)
} else {
    schedule = taskScheduler.scheduleFactory.manual()
}

taskScheduler.scheduleTask(taskConfiguration, schedule)
