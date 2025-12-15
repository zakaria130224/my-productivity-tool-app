import { StyleSheet, View, Text, FlatList, TouchableOpacity, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

type House = {
  id: string;
  name: string;
  address: string;
  rent: number;
  status: 'vacant' | 'rented';
  currentTenant?: {
    name: string;
    phone: string;
    startDate: string;
  };
};

export default function HomeScreen() {
  const router = useRouter();
  const [houses, setHouses] = useState<House[]>([]);

  useEffect(() => {
    loadHouses();
  }, []);

  const loadHouses = async () => {
    try {
      const data = await AsyncStorage.getItem('houses');
      if (data) {
        setHouses(JSON.parse(data));
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to load houses');
    }
  };

  const totalIncome = houses
    .filter(house => house.status === 'rented')
    .reduce((sum, house) => sum + house.rent, 0);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>House Rent Manager</Text>

      <View style={styles.stats}>
        <Text>Total Houses: {houses.length}</Text>
        <Text>Total Income: ৳{totalIncome}</Text>
      </View>

      <TouchableOpacity
        style={styles.addButton}
        onPress={() => router.push('/add-house')}
      >
        <Text style={styles.addButtonText}>+ Add House</Text>
      </TouchableOpacity>

      <FlatList
        data={houses}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.houseCard}
            onPress={() => router.push(`/house-details?id=${item.id}`)}
          >
            <Text style={styles.houseName}>{item.name}</Text>
            <Text>{item.address}</Text>
            <Text>Rent: ৳{item.rent}</Text>
            <Text>Status: {item.status}</Text>
            {item.currentTenant && (
              <Text>Tenant: {item.currentTenant.name}</Text>
            )}
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    marginTop: 40,
  },
  stats: {
    marginBottom: 20,
    padding: 10,
    backgroundColor: '#f0f0f0',
    borderRadius: 5,
  },
  addButton: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 5,
    marginBottom: 20,
  },
  addButtonText: {
    color: '#fff',
    textAlign: 'center',
    fontWeight: 'bold',
  },
  houseCard: {
    padding: 15,
    marginBottom: 10,
    backgroundColor: '#f9f9f9',
    borderRadius: 5,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  houseName: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
  },
});
