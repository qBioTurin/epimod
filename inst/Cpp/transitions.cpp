// Keeps indexes of all places with population belonging to age class A3.
vector<vector<int>> indexes_age_classes;
// Keeps the current population size for each age class with the modification time
vector<pair<double,double>> age_class_size;
// Keeps the mapping between a transition and its index in the data structure age_class_size
unordered_map<string,int> transition_idx;

// Probability managing the primary vaccination failure
static double prob = -1;

// Probabilities managing the infection diffusion
// prob1= boost dopo infezione, prob2=infettare susceptible, prob3= infettare recovered in l1
static double prob1 = -1 , prob2 = -1, prob3 = -1;

// Contact rates for different combinations of age classes
static unordered_map <string,double> contact;

// Born rates for different years in the range 1995-2016
// Rates for the system without vaccination
static unordered_map <int,double> b_rates;

// Vaccination rates for different years in the range 1995-2016
static unordered_map <int,double> v_rates;

// Death rates for different years and age classes in the range 1974-1195
static unordered_map <string, unordered_map<int, double>> d_rates;

// Contact rates
static unordered_map <string, double> contact_rates;

/* Read data from file and fill probabilities */
void read_probabilities(string fname, double& p1, double& p2, double& p3, double& p)
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
					p1 = stod(line);
					cout << "p" << i << ": " << line << "\t" << p1 << endl;
					break;
				case 2:
					p2 = stod(line);
					cout << "p" << i << ": " << line << "\t" << p2 << endl;
					break;
				case 3:
					p3 = stod(line);
					cout << "p" << i << ": " << line << "\t" << p3 << endl;
					break;
				case 4:
					p = stod(line);
					cout << "p" << i << ": " << line << "\t" << p << endl;
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

/* Read data from file and fill a map<int,double> */
void read_map_int_double(string fname, unordered_map<int,double>& m)
{
	ifstream f (fname);
	string line;
	if(f.is_open())
	{
		int i = 0;
		cout << "#### " << fname << "####" << endl;
		while (getline(f,line))
		{
			m.insert(pair<int,double>(i, stod(line)));
			cout << i << "\t" << m[i] << endl;
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

/* Read data from file and fill a map<string,double> */
void read_map_string_double(string fname, unordered_map<string,double>& m)
{
	ifstream f (fname);
	string line;
	if(f.is_open())
	{
		vector<string> infect_cls;
		size_t pos = 0, c_pos = 0, length = 0;
		cout << "#### " << fname << "####" << endl;
		for(int j = 1; j <= 3; j++)
		{
			infect_cls.push_back("b_a"+to_string(j));
			cout << "         ";
			cout << "b_a"+to_string(j);
		}
		cout << endl;
		int j = 1;
		while (getline(f,line))
		{
			int i = 0;
			pos = 0;
			c_pos = 0;
			string a_class = "a_a"+to_string(j);
			// read rates
			cout << " a"+to_string(j) << " ";
			length = line.length();
			do
			{
				pos = line.find(',',c_pos);
				if( pos == string::npos)
					pos = length;
				m.insert(pair<string,double>(a_class+"_"+infect_cls[i], stod(line.substr(c_pos,pos - c_pos))));
				cout << "| " << to_string(m[a_class+"_"+infect_cls[i]]) << " ";
				c_pos = pos+1;
				++i;
			}
			while(pos != length);
			cout << endl;
			++j;
		}
		f.close();
	}
	else
	{
		std::cerr<<"\nUnable to open " << fname << ": file do not exists\n";
		exit(EXIT_FAILURE);
	}
}

/* Read data from file and fill a map<string,map<int,double>> */
void read_map_string_map_int_double(string fname, unordered_map<string,unordered_map<int,double>>& m)
{
	ifstream f (fname);
	if(f.is_open())
	{
		// Each line is a map<int,double>
		// Structure:   "class_name_1",val_1,val_2,..,val_n
		// 		"class_name_2",val_1,val_2,..,val_n
		string line;
		cout << "#### " << fname << "####" << endl;
		int j = 1;
		while (getline(f,line))
		{
			int i = 0;
			size_t pos = 0, c_pos = 0, length = line.length();
			string a_class = "a"+to_string(j++);
			unordered_map<int,double> n;
			do
			{
				pos = line.find(',',c_pos);
				if( pos == string::npos)
					pos = length-1;
				n.insert(pair<int,double>(i, stod(line.substr(c_pos,pos))));
				c_pos = pos+1;
				cout <<  a_class << "-" << i << ": " << n[i] << endl;
				++i;
			}
			while(pos != length-1);
			m.insert(pair<string,unordered_map<int,double>>(a_class,n));
		}
		f.close();
	}
	else
	{
		std::cerr<<"\nUnable to open " << fname << ": file do not exists\n";
		exit(EXIT_FAILURE);
	}
}

void init_data_structures()
{
	read_map_int_double("./b_rates",b_rates);
	read_map_string_double("./c_rates", contact);
	read_map_string_map_int_double("./d_rates", d_rates);
	read_map_int_double("./v_rates",v_rates);
	read_probabilities("./probabilities", prob1, prob2, prob3, prob);
	/* Initialize data structure */
	for(int i =0; i<3; i++)
	{
		pair<double,double> p = {-1.0, 0.0};
		age_class_size.push_back(p);
		vector<int> v;
		indexes_age_classes.push_back(v);
	}
}

void fill_indexes_age_classes(string a_class, int idx, double *Value, map <string,int>& NumPlaces, const double& time)
{
	regex e (a_class);
	regex e1 ("(Count)");
	/* Initialize data structure */
/*	if(age_class_size.size() == 0)
	{
		for(int i =0; i<3; i++)
		{
			pair<double,double> p = {-1.0, 0.0};
			age_class_size.push_back(p);
			//cout << "age_class_size<" << p.first << ", " << p.second << ">" << endl;
			vector<int> v;
			indexes_age_classes.push_back(v);
		}
	}*/
	/* Update the timestamp */
	age_class_size[idx].first = time;
	/* Search for the indexes and compute the age class size */
	for(auto it=NumPlaces.begin(); it!=NumPlaces.end(); it++)
	{
		smatch m, m1;
		regex_search(it->first,m,e);
		regex_search(it->first,m1,e1);
		if(m.size() > 0 && m1.size() == 0)
		{
			/* Populate the vector of indexes for the current age class */
			indexes_age_classes[idx].push_back(it->second);
			/* Compute the current value for the age class siaze */
			age_class_size[idx].second+=Value[it -> second];
//			cout << "age_class_size[" << idx << "]<" << age_class_size[idx].first << ", " << age_class_size[idx].second << ">" << endl;
		}
	}
}

/* It computes such value one for each timestamp. That is, if the function is called 
 * multiple times at the same time instance the computation is done oly oner, then the
 * value is stored to satisfy the subsequent ones.
 * When the function is called for the very first time, it also fill the data structure
 * coupling each place to a specific age class (see fill_indexes_age_classes).
 */
void compute_age_class_size(int idx, double *Value, map <string,int>& NumPlaces, const double& time)
{
	/* if the value for the age class size is not updated, compute it */
	if( time != age_class_size[idx].first )
	{
		/* Update the timestamp */
		age_class_size[idx].first = time;
		/* Comupute the population size for thi age class at this time */
		age_class_size[idx].second = 0;
		for (auto i = indexes_age_classes[idx].begin(); i != indexes_age_classes[idx].end(); i++)
		{
			age_class_size[idx].second+=Value[*i];
		}
//		cout << "Time " << to_string(time)  <<"[" << age_class_size[idx].first << "] age class " << idx+1 << " size " << age_class_size[idx].second << endl;
	}
}

/* Finds index of the age class corresponding to the infect involved in the contact */
int age_class_size_idx(string transition, double *Value, map <string,int>& NumPlaces, const double& time)
{
	auto it = transition_idx.find(transition);
	int idx = -1;
	if( it != transition_idx.end() )
		idx = it -> second;
	else
	{
		/* regex describing the name of the transitions for each age class */
		regex a1 ("(b_a1){1}(_){0}");   // matches strings containing "a1"
		regex a2 ("(b_a2){1}(_){0}");   // matches strings containing "a2"
		regex a3 ("(b_a3){1}(_){0}");   // matches strings containing "a3"
		string a_class = "";
		smatch m;
		/* Identify the age class */
		if(regex_search(transition,m,a1))
		{
			a_class = "(a1){1}";
			idx = 0;
		}
		else if(regex_search(transition,m,a2))
		{
			a_class = "(a2){1}";
			idx = 1;
		}
		else if(regex_search(transition,m,a3))
		{
			a_class = "(a3){1}";
			idx = 2;
		}
		transition_idx[transition] = idx;
		/* Populate the vector with the indexes of this age class */
		if(indexes_age_classes.size() == 0 || indexes_age_classes[idx].size() == 0)
			fill_indexes_age_classes(a_class, idx, Value, NumPlaces, time);
	}
	if( idx == -1 )
		throw std::invalid_argument( "Age class not found! Please, kill me and check the method 'age_class_size'" );
	else
	{	
		compute_age_class_size(idx,Value, NumPlaces, time);
	}
	return idx;
}

// Manage the born rate: rescale it according to the population dimension to match the born rate in the current year
double Born(double *Value,  map <string,int>& NumTrans,  map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	if( prob1 == -1)
		init_data_structures();
	double population=0;
	for(int idx = 0; idx<3; idx++)
	{
		string a_class = "(a"+to_string(idx+1)+")";
		/* Populate the vector with the indexes of this age class */
		if(indexes_age_classes.size() == 0 || indexes_age_classes[idx].size() == 0)
			fill_indexes_age_classes(a_class, idx, Value, NumPlaces, time);
		compute_age_class_size(idx, Value, NumPlaces, time);
		population += age_class_size[idx].second;
	}
	double in;
	modf(time, &in);
	int Time = (int) in; 
	int year = (Time - Time % 365)/365;
	auto rate_it =  b_rates.find(year); 
	if( rate_it == b_rates.end())
		throw std::invalid_argument( "Birth rate not not found! Please, kill me and check the method 'Born'" );
	else
		return rate_it -> second * population;
}


// Manage the born rate:  change rate according to the current year
double Death(double *Value,  map <string,int>& NumTrans,  map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	if( prob1 == -1)
		init_data_structures();
	double in ;
	modf(time, &in);
	int Time = (int) in; 
	int year = (Time - Time % 365)/365  ;
	std::string delimiter = "_a_";
	std::size_t pos = NameTrans[T].find(delimiter) + delimiter.length();
	std::string age_class =  NameTrans[T].substr (pos, 2);
	double intensity = 1.0;
	for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++)
	{
		intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);
	}
	// return d_rates.find(age_class) -> second.find(year) -> second *intensity;
	auto age_it =  d_rates.find(age_class); 
	if( age_it != d_rates.end())
	{
		auto rate_it =  age_it -> second.find(year);
		if( rate_it != age_it-> second.end())
		{
			return rate_it -> second * intensity;
		}
		else
		{
			throw std::invalid_argument( "Death rate not not found (year)! Please, kill me and check the method 'Death'" );
		}
	}
	else
	{
		throw std::invalid_argument( "Death rate not not found (age class)! Please, kill me and check the method 'Death'" );
	}
}

// Compute the transition rate according to:
// 	- age classes of the patients involved in the contact
//	- Resistance level 
// 		- > L_0 boost
// 		- <= L_0 infection. If the patient is in L_0 it is an infection of a Vaccinated/Recovered and of a susceptible otherwise.
// 		- prob_1  -> natural boost probability
// 		- prob_2 probability to infect a susceptible
// 		- prob_3 probability to infect a recovered in L_0 resistance class
double lambda(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	if( prob1 == -1)
		init_data_structures();
	double rate=0;
	auto c = contact_rates.find(NameTrans[T]);
	if(c != contact_rates.end())
		// The transition has already fired and the rate is in the map 
		rate = c -> second;
	else
	{
		// It's the first time the transition fires, hence the rate has to be computed
		auto it=contact.begin();
		bool found = false;
		while(  it!=contact.end() && !found )
		{
			regex e (it->first);
			smatch m;		
			if(regex_search(NameTrans[T],m,e))
			{
				
				// Regular expression matching a primary infection transition
				regex e1 ("(lambdaS_I){1}[s|p]{1}toIp_");
				// Regular expression matching a boost transition
				regex e2 ("(lambda){1}[V|R]{1}i_I[s|p]{1}to[V|R]{1}ii_");
				// Regular expression matching a secondary infection transition
				regex e3 ("(lambda){1}[V|R]{1}1_I{1}[s|p]{1}toIs_");

		                if(regex_search(NameTrans[T],m,e2))
				{
					found = true;
					// Case: boost
					rate=it->second*prob1;  
				//	std::cout << "lambda[" << NameTrans[T] << "] = " << to_string(prob1) << std::endl;
				}
				else if(regex_search(NameTrans[T],m,e1))
				{
					found = true;
					// Case: susceptible infection
					rate=it->second*(prob2);  
				//	std::cout << "lambda[" << NameTrans[T] << "] = " << to_string(prob2) << std::endl;
				}
				else if(regex_search(NameTrans[T],m,e3))
				{
					found = true;
					// Case: recoverd infection
					rate=it->second*(prob3);  
//					std::cout << "lambda[" << NameTrans[T] << "] = " << to_string(prob3) << std::endl;
				}
			}
			++it;
		}
		if(!found) 
		{
			throw std::invalid_argument( "Lambda: transition " + NameTrans[T] + " not not found! Please, kill me and check the method 'lambda'" );
		}
		else
			contact_rates.insert(pair<string,double>(NameTrans[T], rate));
	}
	double intensity = 1.0;
	for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++)
	{
		intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);
	}
	int idx = age_class_size_idx(NameTrans[T], Value, NumPlaces, time);
	return rate*(intensity/age_class_size[idx].second);
}

double vacc(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	if( prob1 == -1)
		init_data_structures();
	double in;
	modf(time, &in);
	int Time = (int) in; 
	int year = (Time - Time % 365)/365;
    
	double intensity = 1.0;
	for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++)
	{
		intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);
	}
	return v_rates.find(year) -> second*intensity;
}

double vaccine(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	return (1-prob)*vacc(Value, NumTrans, NumPlaces,NameTrans, Trans, T, time);
}

double vaccine_failure(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
	return prob*vacc(Value, NumTrans, NumPlaces,NameTrans, Trans, T, time);
}
