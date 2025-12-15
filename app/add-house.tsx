import { StyleSheet, View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export default function AddHouseScreen() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [rent, setRent] = useState('');

  const handleAddHouse = async () => {
    if (!name || !address || !rent) {
      Alert.alert('Error', 'Please fill all fields');
      return;
    }

    try {
      const data = await AsyncStorage.getItem('houses');
      const houses = data ? JSON.parse(data) : [];

      const newHouse = {
        id: Date.now().toString(),
        name,
        address,
        rent: parseFloat(rent),
        status: 'vacant' as const,
      };

      houses.push(newHouse);
      await AsyncStorage.setItem('houses', JSON.stringify(houses));

      Alert.alert('Success', 'House added successfully');
      router.back();
    } catch (error) {
      Alert.alert('Error', 'Failed to add house');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Add New House</Text>

      <TextInput
        style={styles.input}
        placeholder="House Name"
        value={name}
        onChangeText={setName}
      />

      <TextInput
        style={styles.input}
        placeholder="Address"
        value={address}
        onChangeText={setAddress}
      />

      <TextInput
        style={styles.input}
        placeholder="Rent Amount"
        keyboardType="numeric"
        value={rent}
        onChangeText={setRent}
      />

      <TouchableOpacity style={styles.button} onPress={handleAddHouse}>
        <Text style={styles.buttonText}>Add House</Text>
      </TouchableOpacity>
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
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    padding: 15,
    marginBottom: 15,
    borderRadius: 5,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 5,
    marginTop: 10,
  },
  buttonText: {
    color: '#fff',
    textAlign: 'center',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
