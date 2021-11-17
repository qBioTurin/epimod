static double Flag = -1;
static double Infection_rate = 1.428;

void read_constant(string fname, double& Infection_rate)
{
	ifstream f (fname);
	string line;
	if(f.is_open())
	{
		int i = 1;
		while (getline(f,line))
		{
			switch(i)
			{
			case 1:
				Infection_rate = stod(line);
				//cout << "p" << i << ": " << line << "\t" << p1 << endl;
				break;
			}
			++i;
		}
		f.close();
	}
	else
	{
		std::cerr<<"\nUnable to open " << fname <<
			": file do not exists\": file do not exists\n";
		exit(EXIT_FAILURE);
	}
}

void init_data_structures()
{
	read_constant("./Infection", Infection_rate);
	Flag = 1;

}

double InfectionFunction(double *Value,
                         map <string,int>& NumTrans,
                         map <string,int>& NumPlaces,
                         const vector<string> & NameTrans,
                         const struct InfTr* Trans,
                         const int T,
                         const double& time)
{

	// Definition of the function exploited to calculate the rate,
	// in this case for semplicity we define it throught the Mass Action  law

	if( Flag == -1)   init_data_structures();

	double intensity = 1.0;

	for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++)
	{
		intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);
	}

	double rate = Infection_rate * intensity;

	return(rate);
}
