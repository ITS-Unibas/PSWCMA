using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSWCMA.Pre_Requisits
{
    class TaskSchedulerInstaller
    {
        private string name { get; set; }
        private string program { get; set; }
        private string interval { get; set; }
        private string delay { get; set; }

        public TaskSchedulerInstaller(string name, string program, string interval, string delay)
        {
            this.name = name;
            this.program = program;
            this.interval = interval;
            this.delay = delay;
        }

        public bool createTask()
        {
           
            return true;
        }
    }
}
