import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.usb.*;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import java.awt.event.WindowEvent;
import java.awt.event.WindowAdapter;
import java.util.Arrays;

import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import java.util.List;

import java.net.URL;

import jssc.SerialPortList;

import org.apache.commons.lang3.SystemUtils;
import org.apache.commons.io.FileUtils;

/*
 * Hummingbird Firmware Burner - A simple application to upload Hummingbird or custom firmware to the Hummingbird Duo
 * @author Justin Lee
 * @author Tom Lauwers
 */

public class HummingbirdFirmwareBurner extends JFrame{
    private JButton browseButton;
    private JTextField filePath;
    private JPanel BurnerWindow;
    private JLabel statusLabel;
    private JRadioButton revertToHummingbirdModeRadioButton;
    private JRadioButton uploadCustomFirmwareAdvancedRadioButton;
    private JLabel customLabel;
    private JRadioButton switchToHummingbirdArduinoRadioButton;

    public HummingbirdFirmwareBurner() {
        browseButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                JFileChooser chooser = new JFileChooser();
                chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
                chooser.setAcceptAllFileFilterUsed(false);
                chooser.setFileFilter(new FileNameExtensionFilter("Microcontroller Firmware Files (.hex)", "hex")); //only .hex files accepted
                int choice = chooser.showOpenDialog(HummingbirdFirmwareBurner.this);
                if (choice == JFileChooser.APPROVE_OPTION) {
                    filePath.setText(chooser.getSelectedFile().getAbsolutePath());
                }
            }
        });
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowOpened(WindowEvent e) {
                filePath.setVisible(false);
                browseButton.setVisible(false);
                customLabel.setVisible(false);
                (new DuoChecker()).start();
            }
        });
        ActionListener hider = new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e){
                if(uploadCustomFirmwareAdvancedRadioButton.isSelected()){
                    filePath.setVisible(true);
                    browseButton.setVisible(true);
                    customLabel.setVisible(true);
                }
                else{
                    filePath.setVisible(false);
                    browseButton.setVisible(false);
                    customLabel.setVisible(false);
                }
            }
        };
        uploadCustomFirmwareAdvancedRadioButton.addActionListener(hider);
        revertToHummingbirdModeRadioButton.addActionListener(hider);
        switchToHummingbirdArduinoRadioButton.addActionListener(hider);

        setContentPane(BurnerWindow);
        setTitle("Hummingbird Firmware Burner");
        setLocation(100, 100);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        pack();
        setVisible(true);

    }

    class DuoChecker extends Thread {
        private String[] ports = SerialPortList.getPortNames();

        public void run(){
            while(true) {
                if(uploadCustomFirmwareAdvancedRadioButton.isSelected()){
                    if(filePath.getText().equals("")){ //no file chosen yet
                        customLabel.setText("File not yet selected. Browse for custom firmware:");
                    }
                    else if((new File(filePath.getText())).exists() && filePath.getText().substring(filePath.getText().length()-4).equals(".hex")){ //test for valid custom firmware file
                        customLabel.setText("Valid File Selected. Ready for Upload.");
                    }
                    else{ //File does not exist or is not a .hex file
                        customLabel.setText("Invalid file selected. Browse for custom firmware:");
                    }
                }
                try {
                    boolean duo = deviceFound((short) 0x2354, (short) 0x2333,UsbHostManager.getUsbServices().getRootUsbHub()); //Hummingbird in Arduino mode VID & PID
                    boolean hummingbird = deviceFound((short)0x2354,(short) 0x2222,UsbHostManager.getUsbServices().getRootUsbHub()); //Hummingbird VID & PID
                    String[] newPorts;
                    if (duo) { // Arduino Leonardo USB exists
                        statusLabel.setForeground(Color.GREEN);
                        statusLabel.setText("Status: Hummingbird in Arduino Mode Connected");
                    }
                    else if(hummingbird){ //Hummingbird USB exists
                        statusLabel.setForeground(Color.GREEN);
                        statusLabel.setText("Status: Hummingbird in Tethered Mode Connected");
                    }
                    else if(!(Arrays.equals(ports, SerialPortList.getPortNames()))){ //test for different set of serial ports
                        boolean found = false;
                        for(int i = 0;i<5;i++){ //check for bootloader presence a few times since it sometimes takes a second to show up
                            if(deviceFound((short)0x2341,(short)0x0036,UsbHostManager.getUsbServices().getRootUsbHub())) { //Arduino Leonardo bootloader VID & PID - backwards compatibility with beta units
                                found = true;
                                break;
                            }
                            else if(deviceFound((short)0x2354,(short)0x2444,UsbHostManager.getUsbServices().getRootUsbHub())) { //Hummingbird Duo bootloader VID & PID
                                found = true;
                                break;
                            }
                            Thread.sleep(500);
                        }
                        newPorts = SerialPortList.getPortNames(); //refresh list of serial ports
                        if(newPorts.length >= ports.length && found) { //check for new serial port or different serial port
                            String comport = "";
                            if(ports.length==0){ //different lists of ports and first list is empty
                                if(newPorts.length > 0) //prevent any weird array out of bounds errors that might show up
                                    comport = newPorts[0]; //new serial port must be bootloader
                            }
                            else{
                                for(String newPort : newPorts){
                                    if (!Arrays.asList(ports).contains(newPort)) { //find changed or new Serial port
                                        comport = newPort; //bootloader serial port found
                                        break;
                                    }
                                }
                            }
                            String firmwareFile = "";
                            if(revertToHummingbirdModeRadioButton.isSelected()) { // Hummingbird tethered firmware
                                try {
                                    URL url = new URL("http://www.hummingbirdkit.com/sites/default/files/HummingbirdV2.hex");
                                    File file = new File("HummingbirdV2.hex");
                                    FileUtils.copyURLToFile(url,file,2000,2000);
                                    firmwareFile = file.getPath();
                                }catch(Exception e){
                                    System.err.println("Error downloading Hummingbird firmware. Trying offline version.");
                                    firmwareFile = "HummingbirdV2.hex";
                                }
                            }
                            else if(switchToHummingbirdArduinoRadioButton.isSelected()) { //Arduino blink firmware
                                firmwareFile = "BlinkArduino.hex";

                            }
                            else if(uploadCustomFirmwareAdvancedRadioButton.isSelected()) { //custom firmware
                                firmwareFile = filePath.getText(); //get file browsed for by user
                                if(!(new File(firmwareFile)).exists())
                                    firmwareFile = ""; //make sure user has entered valid file location
                            }
                            if(!comport.equals("") && !firmwareFile.equals("")) {
                                statusLabel.setForeground(Color.GREEN);
                                if(revertToHummingbirdModeRadioButton.isSelected())
                                    statusLabel.setText("Status: Reset Detected. Trying to switch to tethered mode.");
                                else if(switchToHummingbirdArduinoRadioButton.isSelected())
                                    statusLabel.setText("Status: Reset Detected. Trying to switch to Arduino mode.");
                                else
                                    statusLabel.setText("Status: Reset Detected. Attempting to upload custom firmware.");
                                Process p;
                                String error = "";
                                try {
                                    String avrdude = "avrdude";
                                    String avrconf ="avrdude.conf";
                                    if(SystemUtils.IS_OS_LINUX){
                                        final String arch = System.getProperty("sun.arch.data.model","");
                                        if(arch.equals("64"))
                                            avrdude = "./avrdude64";
                                        else
                                            avrdude = "./avrdude";
                                    }
                                    else if(SystemUtils.IS_OS_MAC_OSX){
                                        avrdude = "./avrdude_mac";
                                        avrconf = "./avrdude.conf";
                                    }
                                    String[] command={avrdude, "-p", "atmega32u4", "-P", comport, "-c", "avr109", "-C", avrconf, "-b", "9600", "-U", "flash:w:" + firmwareFile+":i"};
                                    //run avrdude
                                    p = Runtime.getRuntime().exec(command);
                                    BufferedReader reader = new BufferedReader(new InputStreamReader(p.getErrorStream()));
                                    String currentLine;
                                    while ((currentLine = reader.readLine()) != null) { //Blocking read from avrdude error stream
                                        error +=currentLine+"\n";
                                    }
                                } catch (Exception e) { //problem running avrdude
                                    System.err.println("Error running avrdude");
                                    e.printStackTrace();
                                }
                                if(error.indexOf("done.  Thank you.")==-1){ //Check for lack of success message
                                    System.err.println(error);
                                    JOptionPane.showMessageDialog(null,"Error uploading firmware. Please try again."+error);
                                }
                                else if(revertToHummingbirdModeRadioButton.isSelected()) {
                                    JOptionPane.showMessageDialog(null, "Done! The status LED should be slowly fading in and out.");
                                } else if(switchToHummingbirdArduinoRadioButton.isSelected()) {
                                    JOptionPane.showMessageDialog(null, "Done! The status LED should now be blinking.");
                                } else {
                                    JOptionPane.showMessageDialog(null,"Done uploading custom firmware.");
                                }
                            }
                        }
                    }
                    else{
                        statusLabel.setForeground(Color.YELLOW);
                        statusLabel.setText("Status: Reset Button Pressed or No Hummingbird Duo Found");
                    }
                    ports = SerialPortList.getPortNames();
                    Thread.sleep(500);
                } catch (UsbException usbEx) {
                    statusLabel.setText("Status: Error with USB connection");
                    usbEx.printStackTrace();
                } catch (InterruptedException iEx) {
                    iEx.printStackTrace();
                }
            }
        }

        public boolean deviceFound(short vid, short pid, UsbHub hub) {
            for (UsbDevice device : (List<UsbDevice>) hub.getAttachedUsbDevices()) { //iterate through all USB devices
                UsbDeviceDescriptor descriptor = device.getUsbDeviceDescriptor();
                if ((descriptor.idVendor() == vid && descriptor.idProduct() == pid) || //matching device VID & PID
                        (device.isUsbHub() && deviceFound(vid, pid,(UsbHub) device))) //if device is hub, search devices in hub
                    return true;
            }
            return false; //return false if no devices found
        }
    }

    public static void main(String[] args) {
        try {
            if(SystemUtils.IS_OS_LINUX) //Set Linux L&F to GTK+
                UIManager.setLookAndFeel("com.sun.java.swing.plaf.gtk.GTKLookAndFeel");
            else // Set System L&F
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        //JOptionPane.showMessageDialog(null,System.getProperty("user.dir"));
        //open JFrame
        HummingbirdFirmwareBurner frame = new HummingbirdFirmwareBurner();
    }
}
