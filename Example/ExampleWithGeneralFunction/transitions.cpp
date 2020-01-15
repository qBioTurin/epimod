
double BirthPredator(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time)
{
    double rate = 1.0;
    double intensity = 1.0;
    for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++)
    {
        intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);
    }
    return(rate*intensity)
}
