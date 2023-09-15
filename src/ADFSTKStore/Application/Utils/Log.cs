using System.Diagnostics;

namespace ADFSTk.Utils
{
    #region Log
    /// <summary>
    /// Log class
    /// </summary>
    public static class Log
    {
        private const string EventLogSource = "ADFSTkTool";
        private const string EventLogGroup = "ADFSToolkit";

        /// <summary>
        /// Log constructor
        /// </summary>
        static Log()
        {
            //if (!EventLog.SourceExists(Log.EventLogSource))
            //    EventLog.CreateEventSource(Log.EventLogSource, Log.EventLogGroup);
        }

        /// <summary>
        /// WriteEntry method implementation
        /// </summary>
        public static void WriteEntry(string message, EventLogEntryType type, int eventID)
        {
            EventLog.WriteEntry(EventLogSource, message, type, eventID);
        }
    }
    #endregion
}
