#############################################################################
# YOUR GENERATIVE MODEL
# ---------------------
# Should be implemented in the 'generative_model' function
# !! *DO NOT MODIFY THE NAME OF THE FUNCTION* !!
#
# You can store your parameters in any format you want (npy, h5, json, yaml, ...)
# <!> *SAVE YOUR PARAMETERS IN THE parameters/ DICRECTORY* <!>
#
# See below an example of a generative model
# Z,x |-> G_\theta(Z,x)
############################################################################

# <!> DO NOT ADD ANY OTHER ARGUMENTS <!>

import tensorflow as tf

def sample_from_noise_tf(data, shape):

    flat_noise = data.flatten()
    
    indices = np.random.choice(len(flat_noise), size=np.prod(shape), replace=True)
    
    sampled_noise = flat_noise[indices]
    
    return tf.convert_to_tensor(sampled_noise.reshape(shape), dtype=tf.float32)

def generative_model(noise, scenario):
    """
    Generative model

    Parameters
    ----------
    noise : ndarray with shape (n_samples, n_dim=4)
        input noise of the generative model
    scenario: ndarray with shape (n_samples, n_scenarios=9)
        input categorical variable of the conditional generative model
    """


    non_zero_indices = [index for index, value in enumerate(scenario[1,]) if value != 0]

    scenario = int(non_zero_indices[0] + 1)

    if scenario == 1:
        model = tf.keras.models.load_model('parameters/generator_scen_1.h5')
        latent_variable = noise[:,:32]

    if scenario == 2:
        model = tf.keras.models.load_model('parameters/generator_scen_2.h5')
        latent_variable = noise[:,:32]

    if scenario == 3:
        model = tf.keras.models.load_model('parameters/generator_scen_3.h5')
        latent_variable = noise[:,:32] 

    if scenario == 4:
        model = tf.keras.models.load_model('parameters/generator_scen_4.h5')
        latent_variable = noise[:,:32] 

    if scenario == 5:
        model = tf.keras.models.load_model('parameters/generator_scen_5.h5')
        latent_variable = noise[:,:32] 

    if scenario == 6:
        model = tf.keras.models.load_model('parameters/generator_scen_6.h5')
        latent_variable = noise[:,:32] 

    if scenario == 7:
        model = tf.keras.models.load_model('parameters/generator_scen_7.h5')
        latent_variable = noise[:,:32] 

    if scenario == 8:
        model = tf.keras.models.load_model('parameters/generator_scen_8.h5')
        latent_variable = noise[:,:32] 

    if scenario == 9:
        model = tf.keras.models.load_model('parameters/generator_scen_9.h5')
        latent_variable = noise[:,:32] 


    return model(latent_variable) # G(Z)
    # return model(latent_variable, scenario) # G(Z, x)




