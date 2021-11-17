static double Flag = -1;
static double a;
static double h;
static double eps;


void read_constant(string fname, double& h, double& a, double& eps)
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
				h = stod(line);
				//cout << "p" << i << ": " << line << "\t" << p1 << endl;
				break;
			case 2:
				a = stod(line);
				//cout << "p" << i << ": " << line << "\t" << p1 << endl;
				break;
			case 3:
				eps = stod(line);
				//cout << "p" << i << ": " << line << "\t" << p1 << endl;
				break;
			}
			++i;
		}
		f.close();
	}
	else
	{
		std::cerr<<"\nUnable to open " << fname << ": file do not exists\": file do not exists\n";
		exit(EXIT_FAILURE);
	}
}

void init_data_structures()
{
	read_constant("./DeathPrey", a, h, eps);
	read_constant("./BirthPredator", a, h, eps);
	Flag = 1;
}

double BirthPredator(double *Value,
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

	int idxPrey = NumPlaces.find("Prey") -> second ;
	int idxPredator = NumPlaces.find("Predator") -> second ;

	double Predator = Value[idxPredator];
	double Prey = Value[idxPrey];

	double rate = eps * (a * Prey) / (1+ a * h * Prey) * Predator;

	return(rate);
}


double DeathPrey(double *Value,
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

	int idxPrey = NumPlaces.find("Prey") -> second ;
	int idxPredator = NumPlaces.find("Predator") -> second ;

	double Predator = Value[idxPredator];
	double Prey = Value[idxPrey];

	double rate = (a * Prey) / (1+ a * h * Prey) * Predator;

	return(rate);
}
